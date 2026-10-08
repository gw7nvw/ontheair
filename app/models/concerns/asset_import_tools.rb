# frozen_string_literal: true

# typed: false
module AssetImportTools
  extend ActiveSupport::Concern

  def Asset.import_illw(dxccs=['AU','NZ'], update = false)
    read_count = 0
    new_count=0
    updated_count=0
    deleted_count=0

    urls = ['https://wllw.org/index.php/en/', 'https://wllw.org/index.php/en/list-page-2', 'https://wllw.org/index.php/en/list-3']

    urls.each do |url|    
      result = fetch_external_url(url)
      table_count = get_table_count(result)
      for count in 1..table_count do
        table = get_table(result,count)
        headers = get_row(table, 0)
        heading = get_clean_text(get_col(headers, 2))
        if heading == "LIGHTHOUSE NAME"
         row_count=get_row_count(table)
         for row_no in 1..row_count
           row = get_row(table, row_no)
           namecell = get_col(row,2)
           code = get_clean_text(get_col(row,6))
           next if !code or (not dxccs.include?(code[0..1]))
           read_count+=1
           if !namecell or namecell.match("line-through") or namecell.upcase.match('DELETED')
             code = get_clean_text(get_col(row,6))
             a=Asset.find_by(code: code)
             if a
               AdminTask.create(task_type: 'deleted', affected_id: code, affected_table: 'asset', affected_url: a.url, description: "Deleted IILW site")
               deleted_count+=1 if a.is_active==true
               a.is_active=false
               a.valid_to = Time.now if a.valid_to.blank?
               a.save
               puts "Retiring #{code}"
             end
             next
           end
           name = get_clean_text(get_col(row,2))
           if name and name.match(',')
             description = (name.split(',')[1..-1]).join(',')
             name=name.split(',')[0]
           end
           
           dxcc = get_clean_text(get_col(row,3))
           continent = get_clean_text(get_col(row,4))
           loc_url = get_col(row,5)
           loc = extract_lat_long(loc_url)
           if !loc then
             AdminTask.create(task_type: 'error', affected_id: code, affected_table: 'asset',  description: "Failed to add/update IILW site (bad location) #{loc_url.to_json}")
             puts " ************************ MISSING **************************"
             puts loc_url.to_json
             puts " ************************ MISSING **************************"
           end
           if loc
             puts ">>>>>> #{name} #{dxcc} #{continent} #{code} #{loc[:long]} #{loc[:lat]}" 
             a=Asset.find_by(code: code)
             next if a and update==false
             if !a
               a=Asset.new 
               new_count+=1
             end
             
             a.asset_type="illw lighthouse"
             a.is_active=true
             a.name = name
             a.country = dxcc
             a.code = code
             a.location="POINT(#{loc[:long]} #{loc[:lat]})" 
             if a.changed?
               update_count+=1 if !new
               if a.save then
                 AdminTask.create(task_type: 'new', affected_id: a.code, affected_table: 'asset', affected_url: a.url, description: "New ILLW site") if new
                 AdminTask.create(task_type: 'update', affected_id: a.code, affected_table: 'asset', affected_url: a.url, description: "Updated ILLW site #{changed}") if !new
               else
                 AdminTask.create(task_type: 'error', affected_id: a.code, affected_table: 'asset', description: "Failed to create new ILLW site: #{a.to_json}")
               end
             end
           end
         end 
        end 
      end
    end
    AdminTask.create(task_type: 'report', affected_table: 'asset', description: "Updated #{dxccs} ILLW lighthouses. Read: #{read_count}, New: #{new_count}, Updated: #{updated_count}, Deleted: #{deleted_count}")

  end

  def Asset.import_vk_pota(update = true, redraw = false, silent=false, resume_at = nil)
    read_count = 0
    new_count=0
    updated_count=0
    deleted_count=0

    need_resume = true if resume_at != nil
    urls = ['https://api.pota.app/park/grids/-43/143/-39/149/0', 'https://api.pota.app/park/grids/-23/113/-11/155/0','https://api.pota.app/park/grids/-30/113/-23/135/0','https://api.pota.app/park/grids/-30/135/-23/155/0','https://api.pota.app/park/grids/-39/113/-35/135/0','https://api.pota.app/park/grids/-39/135/-35/155/0','https://api.pota.app/park/grids/-35/113/-30/155/0']
    urls.each do |url|
      data = nil
      data = fetch_external_url(url)
      begin
        data = JSON.parse(data) if data
      rescue
        AdminTask.create(task_type: 'error', affected_table: 'asset', description: "POTA download failed for #{url}")
        data = nil
      end
      next unless data
      puts 'Found ' + data['features'].count.to_s + ' parks'
      features = data['features']
      features = features.sort_by { |f| f['properties']['reference']}
      features.each do |feature|
        read_count+=1
        properties = feature['properties']
        geometry = feature['geometry']
        puts properties.to_json
        ref = properties['reference']
        need_resume = false if need_resume and resume_at == properties['reference'] 
        if !need_resume then 
          if ref[0..1]=='AU'
            p = Asset.find_by(code: properties['reference'])
            new = false
            unless p
              p = Asset.new
              new = true
              new_count+=1
              puts 'New park'
            else
              puts 'Existing POTA park'
            end
            if new == true or update == true or p.boundary == nil then
              p.asset_type = 'pota park'
              p.code = properties['reference']
              p.safecode = p.get_safecode
              puts p.code
              p.name = properties['name']
              p.is_active = true
              p.url = 'assets/' + p.get_safecode
              puts p.name
              if redraw or new or p.boundary == nil
                #trigger recalc parks
                p.location = "POINT (#{geometry['coordinates'][0]} #{geometry['coordinates'][1]})" if p.location == nil
                if p.name.include?("State Beach") or p.name.include?("Wild and Scenic River")
                   puts "SKIPPING NON-OFFICIAL PARK: #{p.name}"
                else 
                  p.boundary = nil
                  p.boundary_simplified = nil
                  p.boundary_quite_simplified = nil
                  p.boundary_very_simplified = nil
                  p.area = nil
                  p.az_boundary = nil
                  p.az_area = nil
#                  p.old_code = nil 
                  if p.changed?
                    updated_count+=1 if !new
                    changed=p.changed
                    if p.save then
                      AdminTask.create(task_type: 'new', affected_id: p.code, affected_table: 'asset', affected_url: p.url, description: "New POTA site") if new
                      AdminTask.create(task_type: 'update', affected_id: p.code, affected_table: 'asset', affected_url: p.url, description: "Updated POTA site #{changed}") if !new
                    else
                      AdminTask.create(task_type: 'error', affected_id: p.code, affected_table: 'asset', description: "Failed to create new POTA site: #{p.to_json}")
                    end
                    result = p.find_vk_capad_park(silent)
                    p.reload
                    result2 = p.find_vk_state_park(silent)if !p.boundary
                    AdminTask.create(task_type: 'action', affected_id: self.code, affected_table: 'asset', affected_url: self.url, action_url: (self.url||"")+'/map_associate', description: "Could not auto-assign boundary, none found") if !p.boundary
                  end
                end
              else
                #just save
                if p.changed?
                  changed=p.changed
                  if p.save then
                    AdminTask.create(task_type: 'new', affected_id: p.code, affected_table: 'asset', affected_url: p.url, description: "New POTA site") if new
                    AdminTask.create(task_type: 'update', affected_id: p.code, affected_table: 'asset', affected_url: p.url, description: "Updated POTA site #{changed}") if !new
                  else
                    AdminTask.create(task_type: 'error', affected_id: p.code, affected_table: 'asset', description: "Failed to create new POTA site: #{p.to_json}")
                  end
                end
              end
            end
          end
        end
      end
    end
    AdminTask.create(task_type: 'report', affected_table: 'asset', description: "Updated VK WWFF parks. Read: #{read_count}, New: #{new_count}, Updated: #{updated_count}, Deleted: #{deleted_count}")
  end

  def Asset.remove_duplicate_islands()
    ref_ids=Asset.find_by_sql ["select * from (select count(id) as id, ref_id from assets where asset_type='island' and is_active=true group by ref_id) where id>1"]
    ref_ids=ref_ids.pluck(:ref_id)[2..-1]
    ref_ids.each do |ref_id|
      assets = Asset.where(ref_id: ref_id, asset_type: 'island', is_active: true)
      nzgdb = Nzgdb.find_by(feat_id: ref_id, is_active: true)
      count = 0
      puts "================================================"
      assets.each do |asset|
        puts "#{count.to_s} - #{asset.name} (#{asset.code} #{asset.location} matches #{nzgdb.crd_longitude} #{nzgdb.crd_latitude}"
        count += 1
      end
      island=nil
      puts "Select item to retire (or 'a' to skip):"
      id = gets
      island = assets[id.to_i] if id && (id.length > 1) && (id[0] != 'a')
      if island
        puts "DELETE #{island.code} #{island.name}"
        island.update_column(:is_active, false)
        island.update_column(:valid_to, Time.now)
        island.update_column(:description, "Retired as duplicate. #{island.description}")
      end
    end
  end

  def Asset.find_retired_islands
    count = 0
    assets=Asset.where(asset_type: 'island', is_active: true)
    missing=[]
    assets.each do |asset|
      ns = Nzgdb.where(feat_id: asset.ref_id, is_active: true)
      next if ns.count>0
      missing << asset.code 
    end
    if missing.count>10
      puts missing
      puts "ERROR: halting - too many deletions requested"
      AdminTask.create(task_type: 'error', affected_table: 'asset', description: "UPDATE ISLAND RESULTED IN #{missing.count} deletions - ABANDONING!")

    else
      missing.each do |code|
        count+=1
        island=Asset.find_by(code: code)
        puts "DELETE #{island.code} #{island.name}"
        island.update_column(:is_active, false)
        island.update_column(:valid_to, Time.now)
        island.update_column(:description, "Retired as this island has been removed from the NZ Gazeteer (NZGDB). #{island.description}")
      end
    end
    count
  end


  def Asset.update_island_ids()
    assets=Asset.where(asset_type: 'island', ref_id: nil, is_active: true)
    assets.each do |asset|
      ns=Nzgdb.find_by_sql [" select * from nzgdbs where name=? and ST_DWithin(?, ST_Point(crd_longitude, crd_latitude, 4326), 0.01)", asset.name, asset.location]
      n=ns.first
      if n then 
        n2=Nzgdb.find_by(feat_id: n.feat_id, is_active: true)
        puts "#{asset.name} == #{n.name} #{n.feat_id} -> #{n2.name}"
        asset.update_column(:ref_id, n.feat_id)
      else
        nears = Nzgdb.find_by_sql [ "select * from nzgdbs where crd_longitude>? and crd_longitude<? and crd_latitude>? and crd_latitude<? order by (abs(crd_latitude - ?)+abs(crd_longitude - ?)) limit 10", asset.location.x-0.01, asset.location.x+0.01, asset.location.y-0.01, asset.location.y+0.01, asset.location.y, asset.location.x ]
        count = 0
        puts "================================================"
        nears.each do |pp|
          as=Asset.where(ref_id: pp.feat_id, is_active: true).count
          puts "#{count.to_s} - #{pp.name} (#{pp.feat_id}: #{as} matches) == #{asset.name}"
          count += 1
        end
        island=nil
        puts "Select match (or 'a' to skip):"
        id = gets
        island = nears[id.to_i] if id && (id.length > 1) && (id[0] != 'a')
        if island then
          n2=Nzgdb.find_by(feat_id: island.feat_id, is_active: true)
          puts "#{asset.name} == #{island.name} #{island.feat_id} -> #{n2.name}"
          asset.update_column(:ref_id, n2.feat_id)
        end
      end
    end
  end

  def Asset.import_island(update = true, redraw = false, silent=false) 
    read_count = 0
    new_count=0
    updated_count=0
    deleted_count=0

    Nzgdb.where(feat_type: 'Island', is_active: true).order(:name).each do |place|
      read_count+=1
      asset = Asset.find_by(ref_id: place.feat_id, asset_type: 'island')
      if !asset
        asset = Asset.new
        puts "ADDING NEW ISLAND"
        new = true
        new_count+=1
      end
      #log this code as present for missing code deletion test later
      if new == true or update == true or asset.boundary == nil then
        puts "UPDATING #{asset.name} for #{place.name}" if asset.name!=place.name
        asset.asset_type = 'island'
        asset.is_active = true if new
        old_name=asset.name || ""
        asset.name = place.name
        asset.location = "POINT(#{place.crd_longitude} #{place.crd_latitude})" if new
        asset.ref_id = place.feat_id
        asset.description = (place.info_description||"")+"; "+(place.info_origin||"")
        if asset.changed?
          updated_count+=1 if !new
          changed=asset.changed
          puts asset.code
          puts "CHANGED: #{changed} from #{old_name} to #{asset.name}"
          loc_changed = asset.changed.include?('location')

          if !new and !loc_changed #quick save without callbacks
            changes = asset.changes_to_save.transform_values(&:last).except('location')
            changes['updated_at'] = Time.current 
            res = asset.update_columns(changes) if changes.any?
          else
            res = asset.save 
          end
          #log this code as present for missing code deletion test later
          if res
            AdminTask.create(task_type: 'new', affected_id: asset.code, affected_table: 'asset', affected_url: asset.url, description: "New ZLOTA island #{asset.name}") if new
            #AdminTask.create(task_type: 'update', affected_id: asset.code, affected_table: 'asset', affected_url: asset.url, description: "Updated ZLOTA island #{changed}") if !new
          else
            AdminTask.create(task_type: 'error', affected_id: asset.code, affected_table: 'asset', description: "Failed to create new ZLOTA island: #{asset.to_json}")
          end
        end 
        if new == true or redraw == true or asset.boundary == nil
          #look up topo50 boundary
          Asset.get_island_polygons(asset, !new)
        end
      end
    end

    #now retire non-nzgdb islands
    deleted_count=find_retired_islands
    AdminTask.create(task_type: 'report', affected_table: 'asset', description: "Updated ZLOTA lakes. Read: #{read_count}, New: #{new_count}, Updated: #{updated_count}, Deleted: #{deleted_count}")
  end

  def Asset.get_island_polygons(island, quiet)
    islands = IslandPolygon.find_by_sql ["select * from island_polygons where ST_Within(ST_GeomFromText('" + island.location.as_text + "',4326), boundary);"]
    if !islands || islands.count.zero?
      islands = IslandPolygon.find_by_sql [" SELECT *
       FROM island_polygons dp
       WHERE is_active=true and ST_DWithin(ST_GeomFromText('" + island.location.as_text + "', 4326), boundary, 5000, false)
       ORDER BY ST_Distance(ST_GeomFromText('" + island.location.as_text + "', 4326), boundary) LIMIT 50; "]
    end
    if !islands || islands.count.zero?
      AdminTask.create(task_type: 'error', affected_id: island.code, affected_url: island.url, affected_table: 'asset', description: "No polygons found for ZLOTA island: #{island.code}") if !quiet
      puts "NO POLYGONS FOUND AT LOCATION" if !quiet
      return false
    end

    found = false
    islands.each do |lk|
      l_name = (lk.name||"").tr('ū', 'u')
      l_name = l_name.gsub(' / ', ' ')
      l_name = l_name.tr('/', ' ')
      l_name = l_name.gsub(' (', ' ')
      l_name = l_name.gsub(' (', ' ')
      l_name = l_name.tr(')', ' ')
      l_name = l_name.tr(')', ' ')
      l_name = l_name.gsub(/[^0-9a-z]/i, '')
      island_name = (island.name||"").tr('ū', 'u')
      island_name = island_name.gsub(' / ', ' ')
      island_name = island_name.tr('/', ' ')
      island_name = island_name.gsub(' (', ' ')
      island_name = island_name.gsub(' (', ' ')
      island_name = island_name.tr(')', ' ')
      island_name = island_name.tr(')', ' ')
      island_name = island_name.gsub(/[^0-9a-z]/i, '')

      island_arr = island_name.split(' ').sort
      l_arr = l_name.split(' ').sort

      next unless (found == false) && ((l_name == island_name) || (island_arr & l_arr == l_arr) || island_arr & l_arr == island_arr || l_name.include?(island_name) || island_name.include?(l_name))

      if lk.name != island.name then 
        puts 'Matched ' + (island.name || 'unnamed') + ' with ' + (lk.name || 'unnamed') 
        AdminTask.create(task_type: 'update', affected_id: island.code, affected_url: island.url, affected_table: 'asset', description: "Matched #{(island.name || 'unnamed')} with #{(lk.name || 'unnamed')}")
      end
      island.boundary = lk.boundary
      island.save
      found = true
    end
    if found == false then 
      AdminTask.create(task_type: 'error', affected_id: island.code, affected_url: island.url, affected_table: 'asset', description: "Failed to find #{(island.name || 'unnamed')}. Best was #{islands.first.name}") if !quiet
      puts 'Failed to find ' + (island.name || 'unnamed') + '. Best was ' + islands.first.name 
    end
    true
  end

  def Asset.import_lake(update = true, redraw = false, silent=false) 
    read_count = 0
    new_count=0
    updated_count=0
    deleted_count=0

    included_asset_codes = []
    Nzgdb.where(feat_type: 'Lake', is_active: true).each do |place|
      read_count+=1
      asset = Asset.find_by(ref_id: place.feat_id, asset_type: 'lake')
      if !asset
        asset = Asset.new
        puts "ADDING NEW LAKE"
        new = true
        new_count+=1
      end
      #log this code as present for missing code deletion test later
      included_asset_codes << asset.code  if asset.code
      if new == true or update == true or asset.boundary == nil then
        asset.asset_type = 'lake'
        asset.is_active = true
        asset.name = place.name
        asset.location = "POINT(#{place.crd_longitude} #{place.crd_latitude})" if new
        asset.ref_id = place.feat_id
        asset.description = (place.info_description||"")+"; "+(place.info_origin||"")
        if asset.changed?
          updated_count+=1 if !new
          changed=asset.changed
          puts asset.code
          puts "CHANGED: #{changed}"
          loc_changed = asset.changed.include?('location')

          if !new and !loc_changed #quick save without callbacks
            changes = asset.changes_to_save.transform_values(&:last).except('location')
            changes['updated_at'] = Time.current 
            res = asset.update_columns(changes) if changes.any?
          else
            res = asset.save 
          end
          #log this code as present for missing code deletion test later
          included_asset_codes << asset.code  if new
          if res
            AdminTask.create(task_type: 'new', affected_id: asset.code, affected_table: 'asset', affected_url: asset.url, description: "New ZLOTA lake #{asset.name}") if new
            #AdminTask.create(task_type: 'update', affected_id: asset.code, affected_table: 'asset', affected_url: asset.url, description: "Updated ZLOTA lake #{changed}") if !new
          else
            AdminTask.create(task_type: 'error', affected_id: asset.code, affected_table: 'asset', description: "Failed to create new ZLOTA lake: #{asset.to_json}")
          end
        end 
        if new == true or redraw == true or asset.boundary == nil
          #look up topo50 boundary
          Asset.get_lake_polygons(asset, !new)
        end
      end
    end

    #now retire non-nzgdb lakes
    all_asset_codes=Asset.where(asset_type: 'lake', is_active: true).pluck(:code)
    missing_asset_codes=all_asset_codes - included_asset_codes
    if missing_asset_codes.count>10 then
      puts "ERROR: halting - too many deletions requested"
      AdminTask.create(task_type: 'error', affected_table: 'asset', description: "UPDATE LAKE RESULTED IN #{missing_asset_codes.count} deletions - ABANDONING!")
    else
      missing_asset_codes.each do |code|
        asset=Asset.find_by(code:  code)
        asset.update_column(:is_active, false)
        asset.update_column(:valid_to, Time.now)
        n=Nzgdb.find_by(feat_id: asset.ref_id)
        descr=asset.description
        if n then
           descr=(n.info_description||"")+"; "+(n.info_origin||"")
        end
        descr="RETIRED LAKE: #{code} - not is current NZGDB; "+descr
        asset.update_column(:description, descr)
        puts "RETIRED LAKE: #{code} - not is current NZGDB"
        deleted_count+=1
        AdminTask.create(task_type: 'deleted', affected_id: code, affected_url: asset.url, affected_table: 'asset', description: "RETIRED LAKE: #{code} - not is current NZGDB")
      end
    end 
    AdminTask.create(task_type: 'report', affected_table: 'asset', description: "Updated ZLOTA lakes. Read: #{read_count}, New: #{new_count}, Updated: #{updated_count}, Deleted: #{deleted_count}")

  end

  def Asset.get_lake_polygons(lake, quiet)
    lakes = LakePolygon.find_by_sql ["select * from lake_polygons where is_active=true and ST_Within(ST_GeomFromText('" + lake.location.as_text + "',4326), boundary);"]
    if !lakes || lakes.count.zero?
      lakes = LakePolygon.find_by_sql [" SELECT *
       FROM lake_polygons dp
       WHERE is_active=true and ST_DWithin(ST_GeomFromText('" + lake.location.as_text + "', 4326), boundary, 5000, false)
       ORDER BY ST_Distance(ST_GeomFromText('" + lake.location.as_text + "', 4326), boundary) LIMIT 50; "]
    end
    if !lakes || lakes.count.zero?
      AdminTask.create(task_type: 'error', affected_id: lake.code, affected_url: lake.url, affected_table: 'asset', description: "No polygons found for ZLOTA lake: #{lake.code}") if !quiet
      puts "NO POLYGONS FOUND AT LOCATION" if !quiet
      return false
    end

    found = false
    lakes.each do |lk|
      l_name = lake.name.tr('ū', 'u')
      l_name = l_name.gsub(' / ', ' ')
      l_name = l_name.tr('/', ' ')
      l_name = l_name.gsub(' (', ' ')
      l_name = l_name.gsub(' (', ' ')
      l_name = l_name.tr(')', ' ')
      l_name = l_name.tr(')', ' ')
      l_name = l_name.gsub(/[^0-9a-z]/i, '').gsub('Lakes', '').gsub('Lake', '')
      lake_name = lk.name.tr('ū', 'u')
      lake_name = lake_name.gsub(' / ', ' ')
      lake_name = lake_name.tr('/', ' ')
      lake_name = lake_name.gsub(' (', ' ')
      lake_name = lake_name.gsub(' (', ' ')
      lake_name = lake_name.tr(')', ' ')
      lake_name = lake_name.tr(')', ' ')
      lake_name = lake_name.gsub(/[^0-9a-z]/i, '').gsub('Lakes', '').gsub('Lake', '')

      lake_arr = lake_name.split(' ').sort
      l_arr = l_name.split(' ').sort

      next unless (found == false) && ((l_name == lake_name) || (lake_arr & l_arr == l_arr) || lake_arr & l_arr == lake_arr || l_name.include?(lake_name) || lake_name.include?(l_name))

      if lk.name != lake.name then 
        puts 'Matched ' + (lake.name || 'unnamed') + ' with ' + (lk.name || 'unnamed') 
        AdminTask.create(task_type: 'update', affected_id: lake.code, affected_url: lake.url, affected_table: 'asset', description: "Matched #{(lake.name || 'unnamed')} with #{(lk.name || 'unnamed')}")
      end
      lake.boundary = lk.boundary
      lake.save
      found = true
    end
    if found == false then 
      AdminTask.create(task_type: 'error', affected_id: lake.code, affected_url: lake.url, affected_table: 'asset', description: "Failed to find #{(lake.name || 'unnamed')}. Best was #{lakes.first.name}")
      puts 'Failed to find ' + (lake.name || 'unnamed') + '. Best was ' + lakes.first.name 
    end
    true
  end


 
  def Asset.export_llota(dxcc, filename)
    as = Asset.where(country: dxcc, asset_type: 'llota lake', is_active: true)

    headers = "reference_code, name, region, region_iso_code, longitude, latitude, grid_locator, description, access_info, info_url, is_active"

    rows = []
    as.each do |a|
      row = []
      row.push(a.code)
      row.push(a.name)
      #handle blank regions
      if a.region == "" or a.region == nil then
        l=Asset.find_by(code: a.code.gsub("NZLL-","ZLL/"))
        if l then
          a.region=l.region
          a.save
        end
      end
      row.push(a.region_name)
      row.push(a.region)
      row.push(a.location.x)
      row.push(a.location.y)
      row.push("")
      row.push('"'+a.description.gsub('"',"'")+'"')
      if a.public_access == true then
        access = "Public access to AZ exists:\n"
        if a.access_road_ids !=nil then
          road_names=[]
          unnamed_road=0
          access+= "Via public road(s):\n"
          a.access_road_ids.each do |rid|
            r=Road.find_by(t50_fid: rid)
            if r and r.name and r.name.length>0
              road_names+=[r.name.downcase.titlecase]
            else unnamed_road+=1 end
          end
          if unnamed_road>0 then road_names+=[unnamed_road.to_s+" unnamed road(s)"] end
          access+= road_names.uniq.join('; ')
          access+="\n"
        end

        if a.access_track_ids != nil then
          access+="Via DOC track(s):\n"
          unnamed_track=0
          track_names=[]
          a.access_track_ids.each do |rid|
            r=DocTrack.find_by(ogc_fid: rid)
            if r and r.name and r.name.length>0
              track_names+=[r.name.downcase.titlecase]
            else
              unnamed_track+=1
            end
          end
          if unnamed_track>0 then track_names+=[unnamed_track.to_s+" unnamed track(s)"] end
          access+= track_names.uniq.join('; ')
          access+= "\n"
        end
     
        if a.access_park_ids != nil then
          access+= "Via park(s):\n"
          park_names=[]
          a.access_park_ids.each do |rid|
            r=Asset.find_by(id: rid)
            park_names+=[r.name]
          end
          access += park_names.uniq.join('; ')
          access+= "\n"
        end

        if a.access_road_ids == nil and a.access_legal_road_ids != nil then
          access+= "Via unformed legal road(s)\n"
        end
        access+="See the Public Access Layer on the maps under More Information for a detailed map of public access to this lake"
      else
        access = "No public access details are available for this lake. May be accessible only via private land with landowner consent" 
        if a.district == "NZCT1" then 
          access = "Public access data is not currently available for the Chatham Islands"
        end
      end
      row.push('"'+access.gsub('"',"'")+'"')
      row.push("https://ontheair.nz/"+a.url)
      row.push(a.is_active.to_s)
      rows.push(row.join(','))
    end
    f = File.new(filename, "w")
    f.puts(headers)
    rows.each do |row|
      f.puts(row)
    end
    f.close
  
  end

  def Asset.import_sota(dxcc, update=false)
    require 'csv'
    read_count = 0
    new_count=0
    updated_count=0
    deleted_count=0

    dxcc_len=dxcc.length-1
    url = "https://storage.sota.org.uk/summitslist.csv"
    data = fetch_external_url(url)
    data = "SummitCode"+data.split('SummitCode')[1]
    fields = data.parse_csv
    values = CSV(data).read
    rowcount = 0
    values.each do |s|
      if rowcount!=0
        new = false
        code = s[fields.index("SummitCode")]
        if code[0..dxcc_len]==dxcc
          read_count+=1
          a=Asset.find_by(code: code)
          if !a then
            a=Asset.new
            puts "NEW SUMMIT #{code}"
            new = true
            new_count+=1
            a.code = code
            a.asset_type='summit'
            #a.country 
          end
          if new or update
            a.name=s[fields.index("SummitName")]
            a.altitude=s[fields.index("AltM")]
            a.location="POINT (#{s[fields.index("Longitude")]} #{s[fields.index("Latitude")]})"
            a.points = s[fields.index("Points")]
            a.valid_to = s[fields.index("ValidTo")] 
            a.valid_from = s[fields.index("ValidFrom")] 
            a.is_active = true
            a.is_active = false if a.valid_to and a.valid_to<=Time.now.strftime("%Y-%m-%d")
            puts a.code
            loc_change = a.changed.include?('location')
            if a.changed?
              updated_count+=1 if !new
              if a.save then
                AdminTask.create(task_type: 'new', affected_id: a.code, affected_table: 'asset', affected_url: a.url, description: "New SOTA site") if new
                AdminTask.create(task_type: 'update', affected_id: a.code, affected_table: 'asset', affected_url: a.url, description: "Updated SOTA site #{changed}") if !new
              else
                AdminTask.create(task_type: 'error', affected_id: a.code, affected_table: 'asset', description: "Failed to create new SOTA site: #{a.to_json}")
              end
            end
            a.reload

            if a.country == 'VK' and loc_change
              a.add_vk_sota_actvation_zone(25)
            end
          end
        end
      end
      rowcount+=1
    end
    AdminTask.create(task_type: 'report', affected_table: 'asset', description: "Updated #{dxcc} SOTA summits. Read: #{read_count}, New: #{new_count}, Updated: #{updated_count}, Deleted: #{deleted_count}")
  end

  def Asset.import_siota
    require 'csv'
    read_count = 0
    new_count=0
    updated_count=0
    deleted_count=0

    url = "https://www.silosontheair.com/data/silos.csv"
    data = fetch_external_url(url)
    fields = data.parse_csv
    values = CSV(data).read

    rowcount = 0
    values.each do |silo|
      new = false
      if rowcount!=0
        read_count+=1
        code = silo[fields.index("SILO_CODE")]
        asset = Asset.find_by(code: code)
        description = silo[fields.index("COMMENT")]
        asc_desc = ""
        asc_desc = description.force_encoding("ISO-8859-1") if description
        if !asset then
          asset = Asset.new
          puts "New Silo"
          new = true
          new_count+=1
        end
        puts code
        asset.location="POINT (#{silo[fields.index("LNG")]} #{silo[fields.index("LAT")]})"
        asset.name=silo[fields.index("NAME")]
        asset.code=code
#        asset.state=nil
        asset.country='VK'
        asset.description=asc_desc if !asc_desc.blank?
        asset.valid_from = silo[fields.index("NOT_BEFORE")]
        asset.valid_to = silo[fields.index("NOT_AFTER")]
        if asset.valid_to == nil then 
          asset.is_active=true
        else
          asset.is_active=false
        end
        asset.asset_type="silo"
        asset.url = 'assets/' + asset.get_safecode
        if asset.changed?
          updated_count+=1 if !new
          changed = asset.changed
          if asset.save then
            AdminTask.create(task_type: 'new', affected_id: asset.code, affected_table: 'asset', affected_url: asset.url, description: "New SiOTA site") if new
            AdminTask.create(task_type: 'update', affected_id: asset.code, affected_table: 'asset', affected_url: asset.url, description: "Updated SiOTA site #{changed}") if !new
          else
            AdminTask.create(task_type: 'error', affected_id: asset.code, affected_table: 'asset', description: "Failed to create new SiOTA site: #{silo.to_json}")
          end
        end
      end
      rowcount+=1
    end
    AdminTask.create(task_type: 'report', affected_table: 'asset', description: "Updated SiOTA silos. Read: #{read_count}, New: #{new_count}, Updated: #{updated_count}, Deleted: #{deleted_count}")

  end

  # rerun boundary searches using PnP coordinate data
  # prams:
  #  - ignore - set to true to run in automated form assume 'N' to any user questions
  #  - overwrite - set to true to overwrite existing boundaries. Leave at false to only
  #                process parks with no boundary
  #  - start - supply reference to use a > condition to restart a part complete pass
  #
  # Asset.get_wwff_pnp_coordinates(true, true)   process all parks that can be done automatically
  # Asset.get_wwff_pnp_coordinates() -           then handle the manual-intervention-required ones 
  def Asset.get_wwff_pnp_coordinates(ignore=false, overwrite=false, start="", theend='zzzzzz')
    errors = []
    url = 'https://parksnpeaks.org/api/sites/WWFF'
    data = JSON.parse(open(url).read)
    if data
      puts 'Found ' + data.count.to_s + ' parks'
      count = 0
      data = data.sort_by { |hsh| hsh["ID"] }
      data.each do |l|
        if l["ID"][0..3]=='VKFF'  and l["ID"]>=start and l["ID"]<=theend then 
          count += 1
          new = false
          a = Asset.find_by(code: l["ID"])
          if !a
            puts "ERROR: unknown park found - #{l["ID"]}"
          elsif overwrite==false and a.boundary!=nil
            #skip
          else
            puts "Updating #{a.code}"
            # ad corrected location from pnp
            a.location = "POINT(#{l["Longitude"]} #{l["Latitude"]})"
            a.boundary = nil
            a.boundary_simplified = nil
            a.boundary_quite_simplified = nil
            a.boundary_very_simplified = nil
            a.area = nil
            a.az_boundary = nil
            a.az_area = nil
            a.old_code = nil 
            # trigger new lookup of location metadata
            a.region = nil
            a.district = nil
            a.state = nil
            a.save

            # get boundaries from CAPAD, etc
            a.find_vk_capad_park(ignore)
            a.reload
            a.find_vk_state_park(ignore)if !a.boundary
            errors += [a.code] if !a.boundary
          end
        end
      end
    end
    puts errors.to_s
    errors
  end

  # update - update attributes of existing records (we always add new ones)
  # redraw - update location and re-derive boundary for existing assets (we always do this for now assets)
  def Asset.import_wwff(dxcc = 'ZL', update = false, redraw = false, silent=false, start="", theend="zzzz")
    require 'csv'
    url = 'https://wwff.co/wwff-data/wwff_directory.csv'
    data = fetch_external_url(url)

    fields = data.parse_csv
    values = CSV(data).read

    read_count = 0
    new_count=0
    updated_count=0
    deleted_count=0

    row_count=0
    values.each do |row|
      row_count+=1
      next if row_count==1  or row[fields.index("reference")]<start or row[fields.index("reference")]>theend
      next unless row[fields.index("dxcc")] == dxcc
#      next unless row[fields.index("status")] == 'active'
      next if row[fields.index("reference")][0..5]=='Select'
      code = row[fields.index("reference")]
      name = row[fields.index("name")]
      next unless name && code
      safename = name.to_s.encode('UTF-8', invalid: :replace, undef: :replace, replace: '?')
      read_count+=1

      puts 'Code: ' + code + ', name: ' + safename.to_json
      p = Asset.find_by(code: code)
      new = false
      if p
        puts "Existing park #{code}"
      else
        puts "NEW"
        puts row.to_json
        p = Asset.new
        new = true
        new_count+=1
      end
      if new or update then
        p.code = code.strip
        p.name = name.strip
        p.country = dxcc
        p.asset_type='wwff park'
        p.valid_from = row[fields.index("validFrom")] if row[fields.index("validFrom")]!="0000-00-00" and row[fields.index("validFrom")]!=nil
        p.valid_to = row[fields.index("validTo")].to_datetime if row[fields.index("validTo")]!="0000-00-00" and row[fields.index("validTo")]!=nil
        if (!p.valid_to and row[fields.index("status")] == 'active')
          p.is_active = true
        else
          p.is_active = false
        end
        p.description = row[fields.index("notes")] if row[fields.index("notes")]
        if p.changed?
          loc_changed = p.changed.include?('location')
          updated_count+=1 if !new

          if !new and !loc_changed #quick save without callbacks
            changes = p.changes_to_save.transform_values(&:last).except('location')
            changes['updated_at'] = Time.current 
            p.update_columns(changes) if changes.any?
          else
            changed = p.changed
            puts "CHANGED: #{p.changed}"
            if p.save then
              AdminTask.create(task_type: 'new', affected_id: p.code, affected_table: 'asset', affected_url: p.url, description: "New WWFF site") if new
              AdminTask.create(task_type: 'update', affected_id: p.code, affected_table: 'asset', affected_url: p.url, description: "Updated WWFF site #{changed}") if !new
            else
              AdminTask.create(task_type: 'error', affected_id: p.code, affected_table: 'asset', description: "Failed to create new WWFF site: #{p.to_json}")
            end
          end
        end
        p.reload
        if (new == true or redraw==true) and p.is_active==true
          p.location = "POINT(#{row[fields.index('longitude')]} #{row[fields.index('latitude')]})"
          # trigger new lookup of location metadata
          p.boundary = nil
          p.boundary_simplified = nil
          p.boundary_quite_simplified = nil
          p.boundary_very_simplified = nil
          p.region = nil
          p.district = nil
          p.state = nil
          p.area = nil
          p.az_boundary = nil
          p.az_area = nil
          p.old_code = nil
          loc_change = p.changed.include?('location')
          p.save
          if p.country == 'ZL'
            p.find_zlota_park(silent)
            p.reload
          elsif p.country == 'VK'
            p.find_vk_capad_park(silent)
            p.reload
            p.find_vk_state_park(silent) if !p.boundary
            AdminTask.create(task_type: 'action', affected_id: p.code, affected_table: 'asset', affected_url: p.url, action_url: (p.url||"")+'/map_associate', description: "Could not auto-assign boundary, none found") if !p.boundary
          end
        else
          puts 'Existing WWFF park'
        end
      end
    end
    AdminTask.create(task_type: 'report', affected_table: 'asset', description: "Updated #{dxcc} WWFF parks. Read: #{read_count}, New: #{new_count}, Updated: #{updated_count}, Deleted: #{deleted_count}")
  end
  
  def Asset.import_krmnpa(update = true)
    url = 'https://parksnpeaks.org/api/sites/KRMNPA'
    data = JSON.parse(open(url).read)
    if data
      puts 'Found ' + data.count.to_s + ' parks'
      count = 0
      data.each do |l|
        if l["KRMNPAID"][0..2]=='3NP' then
          count += 1
          new = false
          a = Asset.find_by(code: l["KRMNPAID"])
          if !a  
            puts "Creating #{l["KRMNPAID"]}"
            a = Asset.new 
            new = true
          else
            puts "Updating #{a.code}"
          end
          if new or update then
            a.asset_type="krmnpa park"
            a.code = l["KRMNPAID"]
            a2 = Asset.find_by(code: l["Location"])
            if a2 then
              puts "Found matching wwff park #{a2.code}"
              a.description = a2.description
              a.boundary = a2.boundary
              a.is_active = a2.is_active
            end
            a.name = l["Name"]
            a.location = "POINT(#{l["Longitude"]} #{l["Latitude"]})"
            a.country = "VK"
            a.save 
          end
        end
      end
    end
  end 

  def Asset.import_sanpcpa(update = true)
    url = 'https://parksnpeaks.org/api/sites/SANPCPA'
    data = JSON.parse(open(url).read)
    if data
      puts 'Found ' + data.count.to_s + ' parks'
      count = 0
      data.each do |l|
        if l["SANPCPAID"][0]=='5' then
          count += 1
          new = false
          a = Asset.find_by(code: l["SANPCPAID"])
          if !a  
            puts "Creating #{l["SANPCPAID"]}"
            a = Asset.new 
            new = true
          else
            puts "Updating #{a.code}"
          end
          if new or update then
            a.asset_type="sanpcpa park"
            a.code = l["SANPCPAID"]
            a2 = Asset.find_by(code: l["Location"])
            if a2 then
              puts "Found matching wwff park #{a2.code}"
              a.description = a2.description
              a.boundary = a2.boundary
              a.is_active = a2.is_active
            end
            a.name = l["Name"]
            a.location = "POINT(#{l["Longitude"]} #{l["Latitude"]})"
            a.country = "VK"
            a.save 
          end
        end
      end
    end

  end 
  def Asset.import_llota(dxcc_filter, update = true, force = false, silent = true)
    read_count = 0
    new_count=0
    updated_count=0
    deleted_count=0

    url = 'https://llota.app/api/public/references?version=lite'
    data = fetch_external_url(url)
    data = JSON.parse(data)
    if data
      puts 'Found ' + data.count.to_s + ' lakes'
      count = 0
      data.each do |l|
        if l["reference_code"][0..4]=='LL'+dxcc_filter+'-' then
          read_count+=1
          count += 1
          new = false
          a = Asset.find_by(code: l["reference_code"])
          if !a  
            puts "Creating #{l["reference_code"]}"
            a = Asset.new 
            new = true
            new_count+=1
          else
            puts "Updating #{a.code}"
          end
          has_changed=false
          if new or update then
            a.asset_type="llota lake"
            a.code = l["reference_code"]
            a.is_active = true
            if a.boundary == nil
              if a.code[0..3]=='LLNZ'
                a2 = Asset.find_by(code: a.code.gsub('LLNZ-','ZLL/'))
                if a2 then
                  puts "Found matching lake #{a2.code}"
                  a.description = a2.description
                  a.boundary = a2.boundary
                a.is_active = a2.is_active
                end
              end
            end
            a.name = l["name"]
            a.location = "POINT(#{l["longitude"]} #{l["latitude"]})"
            dxcc = DxccPrefix.find_by("iso_code = ? and prefix in ('ZL', 'VK')",a.code[2..3])
            a.country = dxcc.prefix if dxcc
            if a.changed?
              updated_count+=1 if !new
              changed=a.changed
              has_changed=true
              if a.save then
                AdminTask.create(task_type: 'new', affected_id: a.code, affected_table: 'asset', affected_url: a.url, description: "New LLOTA site") if new
                AdminTask.create(task_type: 'update', affected_id: a.code, affected_table: 'asset', affected_url: a.url, description: "Updated LLOTA site #{changed}") if !new
              else
                AdminTask.create(task_type: 'error', affected_id: a.code, affected_table: 'asset', description: "Failed to create new LLOTA site: #{a.to_json}")
              end
            end
          end
          if has_changed and (a.boundary == nil or force == true)  and a.country=='VK'
            a.boundary = nil
            a.boundary_simplified = nil
            a.boundary_quite_simplified = nil
            a.boundary_very_simplified = nil
            a.area = nil
            a.az_boundary = nil
            a.az_area = nil

            puts "Searching VK lakes database"
            puts "Area search"
            lakes = VkLake.find_by_sql [ %Q{ SELECT * FROM vk_lakes where ST_DWITHIN(ST_SetSRID(ST_MakePoint(#{l["longitude"]}, #{l["latitude"]}), 4326), wkb_geometry, 0.5) order by st_distance(ST_SetSRID(ST_MakePoint(#{l["longitude"]}, #{l["latitude"]}), 4326), wkb_geometry) } ] 
            id = nil
            if lakes and lakes.count>0
              lake = nil
              puts '==========================================================='
              count = 0
              lakes.each do |pp|
                lake = pp if pp.name.upcase == a.name.upcase and !lake
                puts count.to_s + ' - ' + pp.name + ' == ' + a.name if silent != true
                count += 1
              end
              if !lake 
                if silent==true 
                  AdminTask.create(task_type: 'action', affected_id: a.code, affected_table: 'asset', affected_url: a.url, action_url: (a.url||"")+'/map_associate', description: "Could not auto-assign HYDRO boundary, multiple found")
                else
                  puts "Select match (or 'a' to skip):"
                  id = gets
                  lake = [lakes[id.to_i]] if id && (id.length > 1) && (id[0] != 'a')
                end
              end
            end
            if lake   
               puts "Matching #{a.name} with #{lake.name}"
               a.boundary = lake.wkb_geometry
            else
               puts "ERROR: NOT FOUND !!!!!!!!!!#{ a.name} !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
               AdminTask.create(task_type: 'error', affected_id: a.code, affected_table: 'asset', description: "LLOTA site needsa boundary")
            end
            if a.changed?
              a.save
            end
          end
        end
      end
    end
    AdminTask.create(task_type: 'report', affected_table: 'asset', description: "Updated #{dxcc_filter} LLOTA lakes. Read: #{read_count}, New: #{new_count}, Updated: #{updated_count}, Deleted: #{deleted_count}")
  end
        


  def Asset.add_humps(valid_from=Time.now)
    ps = Hump.where('code is not null')
    ps.each do |p|
      Asset.add_hump(p, nil, valid_from)
    end
  end

  def Asset.add_hump(p, _existing_asset, valid_from)
    puts p.code
    a = Asset.find_by(asset_type: 'hump', code: p.code)
    is_new = false
    unless a
      a = Asset.new
      logger.debug 'Adding new hump'
      is_new = true
    end
    a.asset_type = 'hump'
    a.code = p.code
    #use reference instead of NoName
    if p.name == 'NoName' then
      a.name = p.code
    else
      a.name = p.name
    end
    a.name = a.code if a.name.nil? || (a.name == '')
    a.location = p.location
    a.region = p.region
    a.altitude = p.elevation
    #don't reactivate deactivated humps
    if a.is_active != false then
      a.is_active = (a.name && !a.name.empty? ? true : false)
    end
    if is_new then a.valid_from = valid_from end
    a.save if a.changed?
    logger.debug a.code
    logger.debug a.name
    a
  end

  def Asset.add_lighthouses
    ps = Lighthouse.where('code is not null')
    ps.each do |p|
      Asset.add_lighthouse(p, nil)
    end
  end

  def Asset.add_volcanoes
    ps = Volcano.where('code is not null')
    ps.each do |p|
      Asset.add_volcano(p, nil)
    end
  end

  def Asset.add_volcano(p, _existing_asset)
    a = Asset.find_by(asset_type: 'volcano', code: p.code)
    unless a
      a = Asset.new
      puts 'Adding new volcano'
      a.is_active = true
      a.asset_type = 'volcano'
      a.code = p.code
    end
    a.name = p.name if p.name
    a.description = p.description if p.description and !a.description
    a.location = p.location if p.location
    a.az_radius = p.az_radius if p.az_radius
    a.field_code = p.field_code
    a.save

    awl = AssetWebLink.find_by(asset_code: a.code)
    unless awl
      awl = AssetWebLink.new
      puts 'New link'
    end
    awl.asset_code = a.code
    awl.url = p.url
    awl.link_class = 'other'
    awl.save

    logger.debug a.code
    logger.debug a.name

    a.add_activation_zone(true)
    a
  end

  def Asset.add_lighthouse(p, _existing_asset)
    a = Asset.find_by(asset_type: 'lighthouse', code: p.code)
    unless a
      a = Asset.new
      logger.debug 'Adding new lighthouse'
    end
    a.asset_type = 'lighthouse'
    if (a.description = nil) || (a.description == '') then a.description = (p.loc_type || '').capitalize + ' based ' + (p.str_type == 'lighthouse' ? 'lighthouse' : 'light/beacon') + (p.status ? ' (' + p.status + ')' : '') end
    a.code = p.code
    a.is_active = true
    a.name = p.name
    a.location = p.location
    a.region = p.region
    a.category = 'Maritime NZ' if !p.mnz_id.nil? && (p.mnz_id != '')
    a.is_active = (a.name && !a.name.empty? ? true : false)
    a.save
    logger.debug a.code
    logger.debug a.name
    a
  end


  def Asset.add_vk_capad_park_by_id(id)
    puts "#{self.code} #{self.state} #{self.name}"
    cs = Capad.where("pa_id like '#{id}'")
    if cs.count==1
      #just assign it
      self.boundary = get_capad_boundary(cs.first.pa_id)
      self.old_code = cs.first.pa_id
      self.save
    elsif cs.count>1
      #select from list
      puts "Asset: "+self.name
      count=0
      puts "Found: "
      cs.each do |c| puts (count=count+1).to_s+" "+c.name+" "+c.pa_id.to_s+" Area: "+c.shape_area.to_s+" "+c.capad_type; end
      puts "Select match number or enter to skip:"
      id = gets
      if id.to_i>0 then
        c=cs[id.to_i-1]
        self.old_code = c.pa_id
        self.boundary = get_capad_boundary(c.pa_id)
        self.save
        puts "assigned "+c.name+" to "+self.name
      end
    else
      puts "No matches found"
    end
    #check if point is within polygon
    a = Asset.find_by("ST_contains(boundary, location) and id=#{self.id}") 
    if !a then
      puts "POINT does not lie within new boundary POLYGON"
      location = self.calc_location
      if location
        puts "Updating location"
        self.location = location
        self.save
      end
    end
  end

  def Asset.find_zlota_park(ignore=false)
    searchname = self.name.gsub("'", "''")
    zps = Asset.find_by_sql [" select id, name, code, asset_type, location from assets where asset_type='park' and name='#{searchname}' and is_active=true"]
    if !zps || zps.count.zero?
      # look for best name match
      short_name = searchname
      short_name = short_name.gsub('Forest', '')
      short_name = short_name.gsub('Conservation', '')
      short_name = short_name.gsub('Park', '')
      short_name = short_name.gsub('Area', '')
      short_name = short_name.gsub('Scenic', '')
      short_name = short_name.gsub('Reserve', '')
      short_name = short_name.gsub('Marine', '')
      short_name = short_name.gsub('Wildlife', '')
      short_name = short_name.gsub('Ecological', '')
      short_name = short_name.gsub('National', '')
      short_name = short_name.gsub('Wilderness', '')
      short_name = short_name.gsub('Te', '')
      puts 'no exact match, try like: ' + short_name
      zps = Asset.find_by_sql [" select id, name, code, asset_type, location from assets where asset_type='park' and name ilike '%%#{short_name.strip}%%' and is_active=true"]
      res_id = nil
      if zps && (zps.count > 1)
        if ignore == false
          puts '==========================================================='
          count = 0
          zps.each do |pp|
            puts count.to_s + ' - ' + pp.name + ' == ' + self.name
            count += 1
          end
          puts "Select match (or 'a' to skip):"
          res_id = gets
          zps = [zps[res_id.to_i]] if res_id && (res_id.length > 1) && (res_id[0] != 'a')
        else
          AdminTask.create(task_type: 'action', affected_id: self.code, affected_table: 'asset', affected_url: self.url, action_url: (self.url||"")+'/map_associate', description: "Could not auto-assign ZLP park boundary, multiple found")
        end
      end
    end
    if !zps || zps.count.zero? || (res_id && res_id[0] == 'a')
      if ignore == false
        puts 'enter asset id to match: '
        res_code = gets
        zps = Asset.where(code: res_code.strip)
      else
        AdminTask.create(task_type: 'action', affected_id: self.code, affected_table: 'asset', affected_url: self.url, action_url: (self.url||"")+'/map_associate', description: "Could not auto-assign ZLP park boundary, none found")
      end
    end

    if zps && (zps.count == 1)
      park = Asset.find_by(id: zps.first.id)
      self.location = park.location
      self.boundary = park.boundary
      self.save
      puts "Matched #{name} with #{park.name}"
    else
      puts 'Could not find match. No location'
    end
  end


  def Asset.find_vk_capad_park(ignore=false)
    puts "CAPAD PARK ---------------------------------------------"
   messages = ""
   if true #!self.name.include?("Beach") and !self.name.include?("Wild and Scenic River")
    found=false
    shortname = capad_expand_abbreviations(self.name.upcase)
    if self.old_code and self.old_code.to_i>0 then
      cs = Capad.find_by_sql [ %q{select "objectid", ST_Buffer(ST_Simplify("wkb_geometry",0.0002),0) as "wkb_geometry", "pa_id", "pa_pid", "name", "capad_type", "type_abbr", "iucn", "nrs_pa", "nrs_mpa", "gaz_area", "gis_area", "gaz_date", "latest_gaz", "state", "authority", "datasource", "governance", "comments", "environ", "overlap", "mgt_plan", "res_number", "zone_type", "epbc", "longitude", "latitude", "pa_system", "shape_leng", "shape_area" from capad where pa_id = }+self.old_code.to_s+%q{;} ]
      if cs and cs.count>0 then
        puts "Found by CAPAD ID"
        self.boundary = get_capad_boundary(cs.first.pa_id)
        self.save
        puts self.code
        found = true
      else
        puts "Has id but no boundary!  Why?: "+self.code
      end
    end
    if found==false and self.location and self.location.to_s.length>0
     puts "Searching by location"
     cs = Capad.find_by_sql [ %q{select distinct "wkb_geometry", "pa_id", "pa_pid", "name", "capad_type", "type_abbr", "iucn", "nrs_pa", "nrs_mpa", "gaz_area", "gis_area", "gaz_date", "latest_gaz", "state", "authority", "datasource", "governance", "comments", "environ", "overlap", "mgt_plan", "res_number", "zone_type", "epbc", "longitude", "latitude", "pa_system", "shape_leng", "shape_area" from capad where st_within ( st_geomfromtext('}+self.location.to_s+%q{', 4326), wkb_geometry);} ]
     if cs and cs.count>0 then
       puts "Found #{cs.count} location matches"
       cs = Capad.find_by_sql [ %q{select "objectid", ST_Buffer(ST_Simplify("wkb_geometry",0.0002),0) as "wkb_geometry", "pa_id", "pa_pid", "name", "capad_type", "type_abbr", "iucn", "nrs_pa", "nrs_mpa", "gaz_area", "gis_area", "gaz_date", "latest_gaz", "state", "authority", "datasource", "governance", "comments", "environ", "overlap", "mgt_plan", "res_number", "zone_type", "epbc", "longitude", "latitude", "pa_system", "shape_leng", "shape_area" from capad where st_within ( st_geomfromtext('}+self.location.to_s+%q{', 4326), wkb_geometry);} ]
       found = false
       cs.each do |c|
         c_shortname = capad_expand_abbreviations(c.name+" "+c.capad_type)
         puts shortname.split(" ").uniq.sort.to_s
         puts c_shortname.split(" ").uniq.sort.to_s
         puts c.pa_id
         if found==false and shortname.split(" ").uniq.sort == c_shortname.split(" ").uniq.sort
           self.old_code = c.pa_id
           self.boundary = get_capad_boundary(c.pa_id)
           self.save
           puts "assigned "+c.name+" to "+self.name
           found = true
         end
       end
       if found == false then
         if ignore == true then
           puts "WARNING: ignoring this park which requires user selection"
           AdminTask.create(task_type: 'action', affected_id: self.code, affected_table: 'asset', affected_url: self.url, action_url: (self.url||"")+'/map_associate', description: "Could not auto-assign CAPAD boundary, multiple found")
         else 
           puts "Asset: "+self.name+" ("+shortname+")"
           count=0
           puts "Found: "
           cs.each do |c| puts (count=count+1).to_s+" "+c.name+" "+c.pa_id.to_s+" Area: "+c.shape_area.to_s+" "+c.capad_type; end
           puts "Select match number or enter to skip:"
           id = gets
           if id.to_i>0 then
              c=cs[id.to_i-1]
              self.old_code = c.pa_id
              self.boundary = get_capad_boundary(c.pa_id)
              self.save
              puts "assigned "+c.name+" to "+self.name
           end
         end
       end
     elsif cs and cs.count == 1 or cs.pluck(:pa_id).uniq.count == 1 then
        cs = Capad.find_by_sql [ %q{select "objectid", ST_Buffer(ST_Simplify("wkb_geometry",0.0002),0) as "wkb_geometry", "pa_id", "pa_pid", "name", "capad_type", "type_abbr", "iucn", "nrs_pa", "nrs_mpa", "gaz_area", "gis_area", "gaz_date", "latest_gaz", "state", "authority", "datasource", "governance", "comments", "environ", "overlap", "mgt_plan", "res_number", "zone_type", "epbc", "longitude", "latitude", "pa_system", "shape_leng", "shape_area" from capad where st_within ( st_geomfromtext('}+self.location.to_s+%q{', 4326), wkb_geometry) limit 1;} ]
       if (shortname == cs.first.name) or (shortname == cs.first.name+" "+cs.first.capad_type) or (shortname == (cs.first.name+" "+cs.first.capad_type)[0..shortname.length-1])then
         puts "Found: "+self.name+" = "+cs.first.name+" "+cs.first.capad_type
         self.old_code = cs.first.pa_id
         self.boundary = get_capad_boundary(cs.first.pa_id)
         self.save
       else
         if ignore == true then
           puts "WARNING: ignoring this park which requires user selection"
           AdminTask.create(task_type: 'action', affected_id: self.code, affected_table: 'asset', affected_url: self.url, action_url: (self.url||"")+'/map_associate', description: "Could not auto-assign CAPAD boundary, multiple found")
         else 
           puts "Does not match, use anyway (N/y): "+self.name+" = "+cs.first.name+" "+cs.first.capad_type
           id = gets
           if (id[0] == 'y')  then
             self.old_code = cs.first.pa_id
             self.boundary = get_capad_boundary(cs.first.pa_id)
             self.save
           end
         end
       end
     else
      puts "NO MATCH FOUND for "+self.name
      messages = "NO MATCH FOUND for "+self.name
     end
    end
    cs
   end
   messages
  end
  
  def Asset.capad_expand_abbreviations(name)
    name=name.gsub(" Remote and Natural Area - Schedule 6, National Parks Act", " Remote and Natural Area")
    name=name.upcase
    name=name.gsub('5(1)(H)',' ')
    name=name.gsub(/\([^)]*\)/, ' ')
    name=name.gsub('CCA ZONE 1',' ')
    name=name.gsub('CCA ZONE 2',' ')
    name=name.gsub('CCA ZONE 3',' ')
    name=name.gsub('MT','MOUNT')
    name=name.gsub('CYPAL',' ')
    name=name.gsub('ABORIGINAL',' ')
    name=name.gsub(/\s+/, ' ')
    name=name.gsub(" &"," AND") 
    name=name.gsub(" B.R."," NATURE CONSERVATION RESERVE") 
    name=name.gsub(" B.R"," NATURE CONSERVATION RESERVE") 
    name=name.gsub(" N.C.R."," NATURE CONSERVATION RESERVE")
    name=name.gsub(" N.C.R"," NATURE CONSERVATION RESERVE")
    name=name.gsub(" SS.R."," NATURE CONSERVATION RESERVE")
    name=name.gsub(" SS.R"," NATURE CONSERVATION RESERVE")
    name=name.gsub(" F.R."," NATURE CONSERVATION RESERVE")
    name=name.gsub(" F.R"," NATURE CONSERVATION RESERVE")
    name=name.sub(" S.R."," NATURE CONSERVATION RESERVE")
    name=name.gsub(" S.R"," NATURE CONSERVATION RESERVE")
    name=name.gsub(" F.F.R."," NATURE CONSERVATION RESERVE")
    name=name.gsub(" F.F.R"," NATURE CONSERVATION RESERVE ")
    name=name.gsub(" G.R."," NATURE CONSERVATION RESERVE")
    name=name.gsub(" G.R"," NATURE CONSERVATION RESERVE")
    name=name.gsub(" W.R."," NATURE CONSERVATION RESERVE")
    name=name.gsub(" W.R"," NATURE CONSERVATION RESERVE")
    name=name.gsub(" N.F.S.R."," NATURE CONSERVATION RESERVE")
    name=name.gsub(" N.F.S.R"," NATURE CONSERVATION RESERVE")
    name=name.gsub(" G.L.R."," NATURE CONSERVATION RESERVE")
    name=name.gsub(" G.L.R"," NATURE CONSERVATION RESERVE")
    name=name.gsub(" N.F.R."," NATURE CONSERVATION RESERVE")
    name=name.gsub(" N.F.R"," NATURE CONSERVATION RESERVE")
    name=name.gsub(" BUSHLAND RESERVE"," NATURE CONSERVATION RESERVE")
    name=name.gsub(" NATURE PARK"," NATURE RESERVE")
    name=name.gsub(" NATURE RECREATION AREA"," NATURE REFUGE")
    name=name.gsub(" BUSHLAND COVENANT"," CONSERVATION COVENANT")
    name=name.gsub(" NATURAL FEATURES RESERVE"," NATURE CONSERVATION RESERVE")
    name=name.gsub(" STREAMSIDE RESERVE", " NATURE CONSERVATION RESERVE")
    name=name.gsub(" FLORA RESERVE"," NATURE CONSERVATION RESERVE")
    name=name.gsub(" FLORA & FAUNA RESERVE"," NATURE CONSERVATION RESERVE")
    name=name.gsub(" FLORA AND FAUNA RESERVE"," NATURE CONSERVATION RESERVE")
    name=name.gsub(" WILDLIFE RESERVE"," NATURE CONSERVATION RESERVE")
    name=name.gsub(" NATIVE FOREST RESERVE"," FOREST RESERVE")
    name=name.gsub(" NATURE REFUGE"," NATURE RESERVE")
    name=name.gsub(" STREAMSIDE RESERVE", " NATURE CONSERVATION RESERVE")
    name=name.gsub(" NATURAL FEATURES AND SCENIC RESERVE"," NATURE CONSERVATION RESERVE")
    name=name.gsub(" SCENIC RESERVE", " NATURE CONSERVATION RESERVE")
    name=name.gsub(" GEOLOGICAL RESERVE", " NATURE CONSERVATION RESERVE")
    name=name.gsub(" GIPPSLAND LAKES RESERVE", " NATURE CONSERVATION RESERVE")
    name=name.gsub(" HERITAGE RIVER", " HERITAGE AREA")
    name=name.gsub(/[^A-Za-z0-9 ]/, ' ').upcase
  end

  def Asset.get_capad_boundary(pa_id)
    capad = nil
    capads = Capad.find_by_sql [ %Q{ select ST_Multi(ST_Buffer(ST_Simplify(st_union("wkb_geometry"),0.0002),0)) as "wkb_geometry" from capad where pa_id ='#{pa_id}' group by pa_id} ]
    capad = capads.first.wkb_geometry if capads
    capad
  end

  def Asset.get_state_park_boundary(unique_name)
    capad = nil
    capads = VkStatePark.find_by_sql [ "select ST_Multi(ST_Union(boundary)) as boundary from vk_state_park where unique_name='#{unique_name.gsub("'","''")}' group by unique_name" ]
    capad = capads.first.boundary if capads
    capad
  end

  def Asset.find_vk_state_park(ignore=false)
    puts "STATEPARK =============================================="
    sps = VkStatePark.find_by_sql [ %q{select * from vk_state_park where st_within ( st_geomfromtext('}+self.location.to_s+%q{', 4326), boundary);} ]  if self.location

    if sps and sps.count == 1 then
        found = false
        spsname = (sps.first.name || "").upcase.gsub(/[^A-Z0-9 ]/, '')
        ourname = (self.name.upcase || "").gsub(/[^A-Z0-9 ]/, '')
        if spsname.split(" ").sort == ourname.split(" ").sort  then
          puts spsname.split(" ").sort.to_s
          puts ourname.split(" ").sort.to_s
          found=true
        else
          if ignore == true then
            puts "WARNING: ignoring this park which requires user selection"
            AdminTask.create(task_type: 'action', affected_id: self.code, affected_table: 'asset', affected_url: self.url, action_url: (self.url||"")+'/map_associate', description: "Could not auto-assign STATEPARK boundary, multiple found")
            found = false
          else 
            puts "Does not match, use anyway (N/y): "+self.name+" = "+(sps.first.name || "")
            id = gets
            if (id[0] == 'y')  then
              found = true
            end
          end
        end
        if found == true
          puts "#{self.name} == #{sps.first.unique_name}"
          self.old_code = sps.first.unique_name
          self.boundary = get_state_park_boundary(self.old_code)
          self.save
          found = true
        end
      elsif !sps or sps.count == 0
        puts "Not found #{self.name}"
      else
        if ignore == true then
          puts "WARNING: ignoring this park which requires user selection"
          AdminTask.create(task_type: 'action', affected_id: self.code, affected_table: 'asset', affected_url: self.url, action_url: (self.url||"")+'/map_associate', description: "Could not auto-assign STATEPARK boundary, multiple found")
          found = false
        else 
          puts "Asset: "+self.name
          count=0
          puts "Found: "
          sps.each do |c| puts (count=count+1).to_s+" "+c.unique_name end
          puts "Select match number or enter to skip:"
          id = gets
          if id.to_i>0 then
            c=sps[id.to_i-1]
            self.old_code = c.unique_name
            sp = VkStatePark.find_by_sql [ %q{select ST_Multi(ST_Buffer(ST_Simplify(st_union("boundary"),0.0002),0)) as "boundary" from vk_state_park where id = }+c.id.to_s ]
            self.boundary = get_state_park_boundary(self.old_code)
            self.save
            puts "assigned "+c.name+" to "+self.name
          end
        end
      end
      self.add_simple_boundary
  end

  def Asset.list_wwff_parks_without_boundaries(dxcc)
     assets = Asset.where(" boundary is null and asset_type='wwff park' and country=?", dxcc).order(:code)
     assets.each do |a|
       capads = Capad.find_by_sql [ %Q{select concat(name, ' - ', capad_type) as name from capad where st_within ( st_geomfromtext('#{a.location.to_s}', 4326), wkb_geometry);} ]
       stateparks = VkStatePark.find_by_sql [ %Q{select * from vk_state_park where st_within ( st_geomfromtext('#{a.location.to_s}', 4326), boundary);} ] 
       puts "[#{a.code}] | #{a.name} | #{a.location.x} | #{a.location.y} | (#{(capads.map{ |c| c.name}).uniq.join(', ')}) | (#{(stateparks.map {|s| s.name}).uniq.join(', ')})"
    end
  end
  def Asset.find_missing_boundaries_by_name(dxcc, asset_type, degrees=1, start_at=nil)
     assets = Asset.where(" boundary is null and asset_type=? and country=?", asset_type, dxcc).order(:code)
     start_needed=false
     start_needed = true if start_at != nil
       
     assets.each do |a|
       next if start_needed==true and a.code != start_at
       start_needed = false
       tryagain=true
       while tryagain==true and !a.name.include?('State Beach') and !a.name.include?('State Trail') and !a.name.include?('Wild and Scenic River')  and !a.name.include?('Heritage Area')  and !a.name.include?('Historic Site') and !a.name.include?('National Heritage Site') and !a.name.include?('Historical Monument') and !a.name.include?('Scenic Trail') and !a.name.include?('State Forest')
         puts "Enter name part to search for"
         puts "#{a.code} - #{a.name}"
         simple_name = gets
         simple_name = simple_name.gsub("\n",'')
         if simple_name.length>0
           capads = Capad.find_by_sql [ "select pa_id, name, capad_type,st_astext(st_pointonsurface(wkb_geometry))  as wkb_geometry from capad where name ilike '%%#{simple_name}%%' and ST_Dwithin(wkb_geometry, st_geomfromtext('#{a.location.to_s}', 4326), #{degrees}); " ]
           row = 1
           capads.each do |capad|
             puts "#{row} - #{capad.pa_id} - #{capad.name} - #{capad.capad_type} - #{capad.wkb_geometry}"
             row+=1
           end
         puts "====================="
         puts "#{a.code} - #{a.name}"
         puts "Select match number or enter to skip:"
         id = gets
         id = id.gsub("\n",'')
         if id.to_i>0 then
           tryagain=false
           a.location = capads[id.to_i-1].wkb_geometry
           puts "Applying #{capads[id.to_i-1].wkb_geometry}"
           a.save
           a.find_vk_capad_park
           a.reload
           if a.boundary then
             puts "SUCCESS"
           else
             puts "NOT SET, try again"
             tryagain=true
           end     
         elsif id=="R" then
           tryagain=true
         else
           tryagain=false
           puts "ERROR - continuing without setting"
         end
       else
         puts "Skipping"
         tryagain=false
       end
     end
   end 
  end

  def Asset.add_govt_parks
    if country == 'ZL'
      find_zlota_park
      reload
    elsif country == 'VK'
      find_vk_capad_park
      reload
      find_vk_state_park if !boundary
    end
  end

end

private

  def get_table(body,id)
    this_table=nil
    tables=body.split('<table')
    this_table = tables[id] if tables and tables.count>=id
    this_table=this_table.split('</table>')[0] if this_table
    this_table
  end

  def get_row(body,number)
    rows=body.split('<tr>') if body
    row=rows[number] if rows
    row=row.split('</tr>')[0] if row
  end

  def get_col(body,number)
    rows=body.split(/<td(?:.*?)>/) if  body
    row=rows[number] if rows
    row=row.split('</td>')[0] if row
  end

  def get_table_count(body)
    body.scan("<table").length if body
  end
  def get_row_count(body)
    body.scan("<tr").length if body
  end
  def get_col_count(body)
    body.scan("<td").length if body
  end
  def get_clean_text(body)
    body.gsub(/<[^>]*>/, '').gsub(/\r/,'').gsub(/\n/,'').gsub('&nbsp;','').strip if body
  end
# Helper method to convert Degrees, Minutes, Seconds (DMS) or Degrees with decimals + Hemispheres to Decimal Degrees
def dms_to_decimal(degrees, minutes, seconds, hemisphere)
  dd = degrees.to_f + (minutes.to_f / 60.0) + (seconds.to_f / 3600.0)
  dd = -dd if ['S', 'W'].include?(hemisphere&.upcase)
  dd.round(6)
end

# Decodes a standard Geohash string into [latitude, longitude] using pure Ruby
def decode_geohash(geohash)
  base32 = "0123456789bcdefghjkmnpqrstuvwxyz"
  
  # Set up initial global bounding boxes
  lat_range = [-90.0, 90.0]
  lon_range = [-180.0, 180.0]
  
  is_lon = true # Geohash bit sequences always alternate, starting with Longitude

  geohash.downcase.each_char do |char|
    char_index = base32.index(char)
    return nil if char_index.nil? # Handle unexpected format corruption gracefully

    # Read each character's 5 constituent spatial bits (from highest 16 down to 1)
    [16, 8, 4, 2, 1].each do |mask|
      target_range = is_lon ? lon_range : lat_range
      midpoint = (target_range[0] + target_range[1]) / 2.0

      # Bitwise AND evaluation isolates bounds placement
      if (char_index & mask) != 0
        target_range[0] = midpoint # Upper half
      else
        target_range[1] = midpoint # Lower half
      end
      
      is_lon = !is_lon # Alternate axes for the next bit step
    end
  end

  # Return the midpoint of the final calculated bounding box
  lat = ((lat_range[0] + lat_range[1]) / 2.0).round(6)
  lon = ((lon_range[0] + lon_range[1]) / 2.0).round(6)
  
  [lat, lon]
end

def extract_lat_long(url_string)
  return nil if !url_string
  # Clean and decode URL to handle %20, %27, etc.
  decoded_url = CGI.unescape(url_string)
# 2. SANITISATION PASS: Normalise all layout quirks to safe ASCII/Standard symbols
  decoded_url.gsub!('º', '°')   # Masculine Ordinal (Degree with line under it)
  decoded_url.gsub!(/[‘’′´]/, "'") # Curly single quotes and true typographic primes
  decoded_url.gsub!(/[“”″]/, '"') # Curly double quotes and double typographic primes
  decoded_url.gsub!("°'", '°')   # Empty seconds
  # Fix Scenario 1 Part A: Missing a degree sign entirely before minutes (e.g., 41.2013N -> 41.2013°N)
  # Looks for a decimal group sitting right against an orientation letter
  decoded_url.gsub!(/(\d+\.\d+)([NSnsEWew])/, '\1°\2')

  # Fix Scenario 1 Part B: Missing a minute symbol but has a degree symbol (e.g., 80°36E -> 80°36'E)
  # Looks for a degree sign, numbers, and an immediate orientation character
  decoded_url.gsub!(/(°\s*\d+)([NSnsEWew])/, '\1\'\2')

  # 1. Match standard Google Maps decimal path style: /@51.0482625,2.3653362
  if decoded_url =~ /@(-?\d+\.\d+),(-?\d+\.\d+)/
    return { lat: $1.to_f.round(6), long: $2.to_f.round(6), format: 'Google Path' }
  end

  # 2. Match Bing Maps style: cp=47.721172~-3.952910
  if decoded_url =~ /cp=(-?\d+\.\d+)~(-?\d+\.\d+)/
    return { lat: $1.to_f.round(6), long: $2.to_f.round(6), format: 'Bing Query' }
  end

  # 3. Match Google Maps DMS style: 51°01'N 2°06'E
  # Supports optional seconds if present in other URLs
#  dms_regex = /(\d+)°(\d+)?(?:'(\d+)?")?([NSns])\s+(\d+)°(\d+)?(?:'(\d+)?")?([EWew])/
#dms_regex = /(\d+)°\s*(?:(\d+)')?(?:(\d+)")?\s*([NSns])\s+(\d+)°\s*(?:(\d+)')?(?:(\d+)")?\s*([EWew])/
 dms_regex = /(\d+)°\s*(?:(\d+(?:\.\d+)?)')?(?:(\d+)")?\s*([NSns])\s+(\d+)°\s*(?:(\d+(?:\.\d+)?)')?(?:(\d+)")?\s*([EWew])/

  if match = decoded_url.match(dms_regex)
    lat_deg, lat_min, lat_sec, lat_hemi = match[1], match[2], match[3], match[4]
    lng_deg, lng_min, lng_sec, lng_hemi = match[5], match[6], match[7], match[8]

    lat = dms_to_decimal(lat_deg, lat_min, lat_sec, lat_hemi)
    long = dms_to_decimal(lng_deg, lng_min, lng_sec, lng_hemi)
    return { lat: lat, long: long, format: 'Google DMS' }
  end

  # 4. Match Google Maps Decimals with Direction style: 50.8681°N 1.5826°E
  decimal_dir_regex = /(-?\d+\.\d+)°([NSns])\s+(-?\d+\.\d+)°([EWew])/
  if match = decoded_url.match(decimal_dir_regex)
    lat_val, lat_hemi = match[1].to_f, match[2].upcase
    lng_val, lng_hemi = match[3].to_f, match[4].upcase

    lat = ['S', 'W'].include?(lat_hemi) ? -lat_val : lat_val
    long = ['S', 'W'].include?(lng_hemi) ? -lng_val : lng_val
    return { lat: lat.round(6), long: long.round(6), format: 'Google Decimal+Direction' }
  end
  # 5. Match space-separated raw decimal style: /place/-54.871461 -68.08318/
  if decoded_url =~ /place\/(-?\d+\.\d+)[\s,]+(-?\d+\.\d+)/
    return { lat: $1.to_f.round(6), long: $2.to_f.round(6), format: 'Google Space-Separated Decimal' }
  end
  # 6. Pure Ruby Geohash Match Pattern (e.g. cp=r6xtn47pbhp1)
  if decoded_url =~ /cp=([0-9b-hjkmnp-z]{4,12})/i
    geohash_str = $1
    lat_lon = decode_geohash(geohash_str)
    
    if lat_lon
      return { lat: lat_lon[0], long: lat_lon[1], format: "Bing Geohash (Pure Ruby)" }
    end
  end

  nil # Return nil if no patterns match
end

