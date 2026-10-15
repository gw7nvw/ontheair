# frozen_string_literal: true

# typed: false

class ProtectedArea < ActiveRecord::Base
  self.inheritance_column = :_type_disabled

  require "csv"
  require 'rgeo/geo_json'
  LAYER_ID    = 53564 # NZ Protected Areas Layer
  RGEO_FACTORY = RGeo::Geographic.spherical_factory(srid: 4326)

  # To load new doc parks layer
  # add 'id column tio eaxch row
  # change POLYGON (( to MULTIPOLYGON ((( and ))" to )))"
  # # change row titrles to id, Overlays: nil, NaPALIS_ID: nil, End_Date: nil, Vested: nil, Section: nil, Classified: nil, Legislatio: nil, Recorded_A: nil, Conservati: nil, Control_Ma: nil, Government: nil, Private_Ow: nil, Local_Purp: nil, Type: nil, Start_Date: nil, Name: nil, WKT: nil

  # in psql delete old database: delete from docparks;
  # rails c production
  # Crownparks.my_import(filename.csv)
  # update crownparks set ctrl_mg_vst=NULL where ctrl_mg_vst='NULL'
  # Park.update_table

  establish_connection :zl_gis

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

  def self.merge_nearby
    #  ActiveRecord::Base.connection.execute("update crownparks set master_id=id where master_id is null;")
    count = 0
    hundreds = 0
    conn = Asset.get_custom_connection("cp", "zl_gis", "ontheair", Rails.application.credentials.dig(:production, :database, :password))

    ls = Crownpark.where(is_active: true).order(:id)
    puts ls.count
    ls.each do |l|
      l.reload
      count += 1
      print "#"
      $stdout.flush
      if count >= 100
        count = 0
        hundreds += 1
        puts "Count: " + (hundreds * 100).to_s
      end
      next unless l.is_active && l.name && !l.name.empty?
      ls = Crownpark.find_by_sql [ ' SELECT cp2.id from crownparks cp1
       inner join crownparks cp2
       ON cp2.is_active=true and (cp2.name = cp1.name) and cp2.id != cp1.id and ST_DWithin(cp1."WKT",cp2."WKT", 20000, false)
       where cp1.id= ' + l.id.to_s + ";" ]

      next unless !ls.nil? && ls.count.positive?
      ids = ls.map(&:id).join(",")
      ids = ids + "," + l.id.to_s
      ids.split(",").each do |l2|
        areas = Crownpark.find_by_sql [ ' select ST_Area("WKT") as id from crownparks where id in (' + l2 + "); " ]
        puts "Areas before merge: " + areas.first.id.to_s
      end

      ls.each do |ll|
        ActiveRecord::Base.connection.execute("update crownparks set is_active=false, master_id=" + l.id.to_s + " where id=" + ll.id.to_s + ";")
        l2 = Crownpark.find_by_id(ll)
        #          l2.is_active=false
        #          l2.master_id=l.id;
        #          l2.save
        puts "Merged and deleted " + (l2.name || "unnamed") + " " + l2.id.to_s + " as duplicate of " + (l.name || "unnamed") + l.id.to_s
      end
      ActiveRecord::Base.connection.execute('update crownparks set "WKT"=(select st_multi(ST_CollectionExtract(st_collect("WKT"),3)) as "WKT" from crownparks where id in (' + ids + ")) where id=" + l.id.to_s + "; ")
      badids = Crownpark.find_by_sql [ " select id from crownparks where id=" + l.id.to_s + ' and ST_IsValid("WKT")=false; ' ]
      if badids && badids.count.positive?
        puts "Created invalid geometry"
        ActiveRecord::Base.connection.execute('update crownparks set "WKT"=st_multi(ST_CollectionExtract(ST_MakeValid("WKT"),3)) where id=' + badids.first.id.to_s + ";")
      end

      areas = Crownpark.find_by_sql [ ' select ST_Area("WKT") as id from crownparks where id in (' + l.id.to_s + "); " ]
      puts "Area after merge: " + areas.first.id.to_s
    end
    true
  end

  def self.fix_invalid_polygons
    ids = Crownpark.find_by_sql [ ' select id from crownparks where ST_IsValid("WKT")=false; ' ]
    ids.each do |id|
      puts id.id
      ActiveRecord::Base.connection.execute('update crownparks set "WKT"=st_multi(ST_CollectionExtract(ST_MakeValid("WKT"),3)) where id=' + id.id.to_s + ";")
    end
  end

  def self.get_custom_connection(identifier, dbname, dbuser, password)
    eval("Custom_#{identifier} = Class::new(ActiveRecord::Base)")
    eval("Custom_#{identifier}.establish_connection(:adapter=>'postgis', :database=>'#{dbname}', " \
    ":username=>'#{dbuser}', :password=>'#{password}')")
    eval("Custom_#{identifier}.connection")
  end
end
