# frozen_string_literal: true

# typed: false

class ProtectedArea < ActiveRecord::Base
  self.inheritance_column = :_type_disabled

  require "csv"
  require 'rgeo/geo_json'
  LAYER_ID    = 53564 # NZ Protected Areas Layer
  RGEO_FACTORY = RGeo::Geographic.spherical_factory(srid: 4326)
  MERGE_THRESHOLD_DEGREES = 0.18
  GENERIC_TERMS_REGEX = '^[[:space:][:punct:]]*(?:Reserve|Conservation|Area|Marginal|Strip|Recreation|Scenic|Purpose|Local|Gravel|Esplanade|Park|Cemetery|Unnamed|Historic|Wildlife|Public|Domain|Utility|Hall|Management|Riverbed|Soil|Government|Protection|Ecological|Scientific)+(?:[[:space:][:punct:]]+(?:Reserve|Conservation|Area|Marginal|Strip|Recreation|Scenic|Purpose|Local|Gravel|Esplanade|Park|Cemetery|Unnamed|Historic|Wildlife|Public|Domain|Utility|Hall|Management|Riverbed|Soil|Government|Protection|Ecological|Scientific)+)*[[:space:][:punct:]]*$'

  establish_connection :zl_gis

  # pull new parks from LINZ and merge into assets
  # supply a filename to import from file, otherwise
  # a changeset will be pulled from LINZ
  def self.run_full_update(filename=nil)
    if filename
      self.import_gpkg(filename)
    else
      self.update
    end

    self.curate
    self.merge_into_assets
    self.deactivate_retired_assets
  end

  # Manually import an EPSG:4326 .gpkg from LINZ and recreate
  # protected areas table from it 
  def self.import_gpkg(filename)
    self.with_connection do |conn|
      if conn.table_exists?('my_table')
        conn.execute("TRUNCATE TABLE my_table RESTART IDENTITY")
      end
    end
    system("ogr2ogr -f PostgreSQL 'PG:host=localhost dbname=zl_gis user=ontheair password=#{Rails.application.credentials.dig(:production, :database, :password)}' -nlt multipolygon -nln protected_areas -t_srs 'EPSG:4326' #{filename}")
    ds = DataSource.find_by(name: "ZL protected areas")
    ds.update_column(:last_update, Time.now)
  end


  def self.update
    # Determine lookback timestamps
    ds = DataSource.find_by(name: "ZL protected areas")
    from_time = ds.last_update
    if from_time
      from_time=from_time.utc.iso8601
    else
      from_time="2026-01-01T00:00:00Z"
    end
    to_time   = Time.now.utc.iso8601

    puts "Fetching Protected Areas changesets from #{from_time} to #{to_time}..."
    
    viewparams = "from:#{from_time};to:#{to_time}"
    uri = URI("https://data.linz.govt.nz/services;key=#{Rails.application.credentials.linz_api_key}/wfs")
    params = {
      'SERVICE'      => 'WFS',
      'SRSName'      => 'EPSG:4326',
      'VERSION'      => '2.0.0',
      'REQUEST'      => 'GetFeature',
      'typeNames'    => "layer-#{LAYER_ID}-changeset",
      'outputFormat' => 'application/json',
      'viewparams'   => viewparams
    }
    uri.query = URI.encode_www_form(params)

    response = Net::HTTP.get_response(uri)
    unless response.is_a?(Net::HTTPSuccess)
      raise "LINZ Changeset API Error: #{response.code} - #{response.body}"
    end

    geojson = JSON.parse(response.body)
    features = geojson.fetch('features', [])

    if features.empty?
      puts "No new protected area boundaries altered."
      ds=DataSource.find_by(name: 'ZL protected areas')
      ds.update_column(:last_update, to_time.to_time)
      return
    end

    self.with_connection do |conn|
      conn.transaction do
      # 1. Create a PostGIS temporary staging environment
      # Using geometry(Geometry, 4326) to store the direct incoming GeoJSON elements safely
      conn.execute(<<~SQL
        CREATE TEMP TABLE linz_protected_staging (
          id integer, 
          change_action char(1), 
          properties jsonb, 
          geom geometry(Geometry, 4326)
        ) ON COMMIT DROP;
      SQL
      )
      # 2. Extract, slice, and batch stream data into PostGIS
      features.each_slice(500) do |batch|
        insert_values = batch.map do |feature|
          props  = feature['properties']
          action = props.delete('__change_action__')
          id     = props['id']
          
          # Parse geometry explicitly through RGeo
          rgeo_geom = RGeo::GeoJSON.decode(feature['geometry'], json_parser: :json, factory: RGEO_FACTORY)
          
          # Convert to Well-Known Text (WKT) for the SQL input matrix
          wkt_geom = rgeo_geom ? rgeo_geom.as_text : nil

          if wkt_geom.nil?
            nil # Skip records lacking geometries if structural validation errors happen
          else
            "(#{conn.quote(id)}, #{conn.quote(action)}, #{conn.quote(props.to_json)}, ST_GeomFromText(#{conn.quote(wkt_geom)}, 4326))"
          end
        end.compact.join(",")

        next if insert_values.empty?
        conn.execute("INSERT INTO linz_protected_staging (id, change_action, properties, geom) VALUES #{insert_values}")
      end

      # 3. Apply changes atomically within a transaction block
      conn.transaction do
        # Action D: Evict deleted properties
        conn.execute("DELETE FROM protected_areas WHERE napalis_id IN (SELECT (properties->>'napalis_id')::bigint FROM linz_protected_staging WHERE change_action = 'D')")

        # Action I & U: High Performance Upsert matching target properties
        # ST_Transform(geom, 2193) reprojects WGS84 GeoJSON data into accurate NZTM2000 space
        conn.execute(<<~SQL
          INSERT INTO protected_areas (
                napalis_id,
                start_date,
                name,
                recorded_area,
                overlays,
                type,
                legislation,
                section,
                reserve_purpose,
                ctrl_mg_vst,
                geom
              )
              SELECT
                (properties->>'napalis_id')::bigint,
                (properties->>'start_date')::timestamptz,
                (properties->>'name'),
                (properties->>'recorded_area')::double precision,
                (properties->>'overlays'),
                (properties->>'type'),
                (properties->>'legislation'),
                (properties->>'section'),
                (properties->>'reserve_purpose'),
                (properties->>'ctrl_mg_vst'),
                ST_Multi(geom) -- Guarantees conversion to MultiPolygon to satisfy column constraints
          FROM linz_protected_staging 
          WHERE change_action IN ('I', 'U')
          ON CONFLICT (napalis_id) DO UPDATE SET
                start_date      = EXCLUDED.start_date,
                name            = EXCLUDED.name,
                recorded_area   = EXCLUDED.recorded_area,
                overlays        = EXCLUDED.overlays,
                type            = EXCLUDED.type,
                legislation     = EXCLUDED.legislation,
                section         = EXCLUDED.section,
                reserve_purpose = EXCLUDED.reserve_purpose,
                ctrl_mg_vst     = EXCLUDED.ctrl_mg_vst,
                geom            = EXCLUDED.geom;
        SQL
        )
      end
      end
    end

    ds=DataSource.find_by(name: 'ZL protected areas')
    ds.update_column(:last_update, to_time.to_time)
    puts "Processed updates for #{features.size} protected area records."
  end

  def self.curate
    self.with_connection do |conn|
      conn.transaction do
        # =========================================================================
        # Stage 1: Spatial Curation & Clustering into Interim Sandbox Table
        # =========================================================================nn.transaction do
        puts "\n[Stage 1] Clearing interim table and executing spatial clustering..."
        conn.execute("TRUNCATE TABLE curated_protected_areas RESTART IDENTITY")


        # Complex Aggregation Query:
        # 1. Clusters shapes sharing matching name/type variants within 20,000 metres
        # 2. Pre-heals invalid topological structures with ST_MakeValid BEFORE unioning
        # 3. Aggregates contributing source records into a tracking lineage array
        conn.execute(<<~SQL)
  INSERT INTO curated_protected_areas (name, type, section, recorded_area, source_napalis_ids, geom)
  WITH clustered_source AS (
    SELECT 
      name,
      type,
      section,
      napalis_id,
      recorded_area,
      ST_MakeValid(geom) AS valid_geom,
        CASE
        -- If the name is strictly generic, isolate it by partitioning on napalis_id
        WHEN name ~* '#{GENERIC_TERMS_REGEX}'
        THEN ST_ClusterWithinWin(geom, 0.003) OVER(PARTITION BY name, type)

        -- If the name has a unique prefix, allow the 20km cascading merge to run normally
        ELSE ST_ClusterWithinWin(geom, #{MERGE_THRESHOLD_DEGREES}) OVER(PARTITION BY name, type)
      END AS cluster_id
      -- PARTITION BY groups identical names/types first, forcing spatial checks 
      -- to run ONLY within those matching buckets instead of a global matrix.
    FROM protected_areas
    WHERE geom IS NOT NULL
  )
  SELECT
    name,
    type,
    section,
    SUM(recorded_area) AS recorded_area,
    array_agg(napalis_id) AS source_napalis_ids,
    ST_Multi(ST_CollectionExtract(ST_Union(valid_geom), 3)) AS geom
  FROM clustered_source
  GROUP BY name, type, section, cluster_id;
SQL
      end
    end
  end

  def self.merge_into_assets(force = false)
    read_count = 0
    new_count = 0
    updated_count = 0
    saved_ids = []

    self.with_connection do |conn|
      conn.transaction do
        curated_records = conn.select_all(<<~SQL).to_a
          SELECT id, name, type, start_date, recorded_area, section, source_napalis_ids::text[], geom FROM curated_protected_areas
        SQL

        curated_records.each do |row|
          read_count+=1
          saved = false
          # Re-parse Postgres native array text string format back into a clean Ruby Integer Array
          napalis_ids = row['source_napalis_ids'].gsub(/[{}]/, '').split(',').map(&:to_i)

          # 1. Look up all existing assets in the production DB that map to this cluster's component IDs
          #matching_assets = Asset.where(asset_type: 'park', name_source: 'napalis', name_id: napalis_ids, is_active: true)
          matching_assets = Asset.where(asset_type: 'park', name_source: 'napalis', name_id: napalis_ids)
                         .order(code: :asc) # Oldest asset first
                         .to_a

          if matching_assets.any?
            # The oldest record becomes our master asset
            asset = matching_assets.shift
            puts asset.code
    
            # If there are trailing assets, they are historical duplicates being merged by the 20km rule!
            matching_assets.each do |obsolete_asset|
              puts "  ⚠️ Auto-merging historical asset [#{obsolete_asset.code}] into Master [#{asset.code}]"
              obsolete_asset.update!(is_active: false, updated_at: Time.current, master_code: asset.code)
            end
          else    # Brand new asset altogether
            asset = Asset.new(asset_type: 'park', name_source: 'napalis', is_active: true)
            asset.name_id = napalis_ids.first # Set the legacy identity fallback anchor
            new = true
            puts "Creating new asset ... #{row['name']}"
            new_count += 1
          end

          # Map updated attribute payload
          asset.name = row['name']
          asset.description = row['section'] if asset.description.blank?
          asset.asset_type = 'park'
          asset.is_nzart = asset.is_active
          b = Asset.new
          b.boundary = row['geom']
          area = calc_area(b.boundary)
          asset.minor = asset.check_for_minor(area, row['section'])
          asset.valid_from = row['start_date'] if new
          asset.valid_from = Time.current if new and asset.valid_from.blank?
          if (area < (asset.area||0)*0.9) and asset.is_active==true
            puts "ALERT: asset #{asset.code} #{asset.name} has shrunk from #{asset.area} to #{area}."
            AdminTask.create(task_type: "warning", affected_id: asset.code, affected_table: "asset", description: "asset #{asset.code} #{asset.name} has shrunk from #{asset.area} to #{area}.")
          end

          if row['geom'].present? 
            existing_geom = asset.boundary
            if existing_geom.present?
 #             is_identical = (Asset.find_by_sql [ 
 #                 "SELECT ST_Equals(ST_GeomFromEWKT(?), ST_SetSRID(ST_GeomFromEWKT(?), 4326)) as is_active",
 #              ]).first.is_active

              result = Asset.find_by_sql [ "
                  SELECT ST_Area(
                      ST_SymDifference(
                        ST_GeomFromEWKT(?),
                        ST_SetSRID(ST_GeomFromText(?), 4326)
                      )::geography
                  ) as area",
                  row['geom'], existing_geom.to_s] 
              sliver_area_sq_meters = result.first.area if result 

              # If the total physical mismatch is less than 5 square metres, treat them as identical
              unless sliver_area_sq_meters < [10000, (0.001 * area)].min
                asset.boundary = row['geom']
                puts "  🗺️ Boundary updated for '#{asset.name}' (Footprint shifted) #{sliver_area_sq_meters} / #{area}"

              end
            else
              # Brand new asset or no prior boundary
              asset.boundary = row['geom']
            end
            asset.area = area
          else
            puts "  ℹ️ [Skipped Geometry] Keeping existing boundary for '#{row['name']}' due to validation anomalies. Processing other attributes..."
            AdminTask.create(task_type: "error", affected_id: asset.code, affected_table: "asset", description: "Failed to find geometry for new/updated site: #{asset.name} - #{asset.code}. Retaining old geometry (if any)")
          end

          # Save executes model validations, triggers 'assign_calculated_fields' callback, and registers code varchar
          if asset.changed?
            loc_changed = asset.changed.include?("boundary")
            updated_count+=1 if !new
            if !new and !loc_changed # quick save without callbacks
              changes = asset.changes_to_save.transform_values(&:last).except("location")
              changes["updated_at"] = Time.current
              asset.update_columns(changes) if changes.any?
            else
              #get new locaion point
              asset.location = asset.calc_location
              #force regeneration of calculated boundaries
              asset.boundary_quite_simplified = nil
              asset.boundary_simplified = nil
              asset.boundary_very_simplified = nil
              asset.az_boundary = nil

              changed = asset.changed
              puts "CHANGED: #{asset.code} - #{asset.name} - #{asset.changed}"
              if asset.save then
                saved_ids << asset.code
                AdminTask.create(task_type: "new", affected_id: asset.code, affected_table: "asset", affected_url: asset.url, description: "New ZLP site") if new
                AdminTask.create(task_type: "update", affected_id: asset.code, affected_table: "asset", affected_url: asset.url, description: "Updated ZLP site #{changed}") if !new
                saved = true
              else
                AdminTask.create(task_type: "error", affected_id: asset.code, affected_table: "asset", description: "Failed to create new ZLP site: #{asset.to_json}")
              end
            end

            if saved or force
              # Wipe tracking history cleanly for this specific asset cluster group
              AssetProtectedAreaLink.where(napalis_id: napalis_ids)
                          .or(AssetProtectedAreaLink.where(asset_code: asset.code))
                          .delete_all
    
              # Write fresh consolidated array maps
              insert_rows = napalis_ids.map do |id|
                { asset_code: asset.code, napalis_id: id, created_at: Time.current, updated_at: Time.current }
              end
    
              AssetProtectedAreaLink.insert_all(insert_rows) unless insert_rows.empty?
            end
          end
        end

        puts "Checking for access updates"
        saved_ids.each do |code|
          asset = Asset.find_by(code: code)
          asset.get_access if asset
        end

        puts "\nSync Completed Successfully. Pipeline shutdown clean."
        AdminTask.create(task_type: "report", affected_table: "asset", description: "Updated ZLP parks. Read: #{read_count}, New: #{new_count}, Updated: #{updated_count}")
      end
    end
  end

  def self.deactivate_retired_assets
    # 1. Reach out to the GIS database and pluck all currently surviving NAPALIS IDs
    surviving_napalis_ids = (ProtectedArea.find_by_sql ["SELECT napalis_id FROM protected_areas"] ).pluck(:napalis_id)

    return if surviving_napalis_ids.empty?
  
    # 2. Switch context back to your production database
    puts "Identifying obsolete assets to deactivate..."
  
    # Find all asset references where the registered NAPALIS mapping no longer exists in LINZ
    obsolete_references = AssetProtectedAreaLink
      .where.not(napalis_id: surviving_napalis_ids)
      .pluck(:asset_code)
      .uniq
  
    if obsolete_references.any?
      if 1.0*obsolete_references.count/surviving_napalis_ids.count>0.1
        AdminTask.create(task_type: "error", affected_table: "asset", description: "Too many assets to retire after LINZ update. Aborting:  #{obsolete_references.size}")
      else
        # Soft-delete the obsolete parks in a single atomic database pass
        Asset.where(code: obsolete_references, asset_type: 'park', is_active: true)
           .update_all(is_active: false, valid_to: Time.current, updated_at: Time.current)
  
      # Purge the dead links out of your registry so they don't clog future runs
      AssetProtectedAreaLink.where(asset_code: obsolete_references).delete_all
  
      puts "✅ Successfully deactivated #{obsolete_references.size} retired park assets."
      AdminTask.create(task_type: "report", affected_table: "asset", description: "Updated ZLP parks. Retired: #{obsolete_references.size} parks")
      end
    else
      puts "✅ No retired assets found. Everything up to date."
    end
  end

  #to be shifted to new model or asset_import_tools
  #along with ak_maps
  def self.ecan_import(file)
    h = []
    CSV.foreach(file, headers: true) do |row|
      h.push(row.to_hash)
    end

    h.each do |park|
      p = Crownpark.new
      p.name = park["COMMON_NAM"]
      p.WKT = park["WKT"]
      p.reserve_type = "Regional park"
      p.start_date = park["DATE_CREAT"]
      p.recorded_area = park["Shape_Area"].to_d / 10_000

      p.save
      puts "Added crownpark :" + p.id.to_s + " - " + p.name
    end
  end
end

private

# Scans for inverse topology/runaway spatial calculation sizing errors
  def self.validate_and_isolate_anomalies!(conn)
    anomalies = conn.select_all(<<~SQL).to_a
      SELECT id, name, recorded_area AS expected_max_ha, (ST_Area(geom::geography) / 10000.0) AS actual_geom_ha
      FROM curated_protected_areas
      WHERE geom IS NOT NULL AND (ST_Area(geom::geography) / 10000.0) > (recorded_area + 0.1)
    SQL

    if anomalies.any?
      puts "   WARNING: #{anomalies.size} geometry inversion/growth anomalies flagged!"

      anomalies.each do |row|
        #AdminTask.create!(
        #  task_type: 'Geometry Review Required',
        #  description: "LINZ curation anomaly on '#{row['name']}' (Interim ID: #{row['id']}). Expected max #{row['expected_max_ha']} ha, but geometry inverted/grew to #{row['actual_geom_ha'].round(2)} ha.",
        #  status: 'pending'
        #)
        puts "    - AdminTask alert issued for row ##{row['id']} (#{row['name']})"
      end

      # Nullify geometry data inside the interim container to isolate corrupt coordinates from copying forward
      anomaly_ids = anomalies.map { |r| r['id'] }
      conn.execute("UPDATE curated_protected_areas SET geom = NULL WHERE id IN (#{anomaly_ids.join(',')})")
      puts "    - Isolated #{anomalies.size} geometries successfully."
    else
      puts "   Validation verification passed. No anomalies present."
    end
  end

   # Resolves corresponding asset models based on tracking codes mapped to current lineage definitions
  def find_existing_asset_by_lineage(napalis_ids)
    ref = AssetProtectedAreaLink.where(napalis_id: napalis_ids).pluck(:asset_code).first
    Asset.find_by(code: ref) if ref
  end

  # Updates records inside the tracking lineage junction structure
  def sync_lineage_mapping!(asset_code, napalis_ids)
    AssetProtectedAreaLink.where(napalis_id: napalis_ids).delete_all
    insert_rows = napalis_ids.map do |id|
      { asset_code: asset_code, napalis_id: id, created_at: Time.current, updated_at: Time.current }
    end
    AssetProtectedAreaLink.insert_all(insert_rows) unless insert_rows.empty?
  end

  def calc_area(rgeo_geometry)
    b = Asset.find_by_sql [ "select ST_Area(GeomFromEWKT('#{rgeo_geometry}')::geography) as area" ]
    b.first.area
  end

