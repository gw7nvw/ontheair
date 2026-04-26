# frozen_string_literal: true

# typed: false
module AssetImportTools
  def Asset.import_vk_pota(update = true)
    urls = ['https://api.pota.app/park/grids/-43/143/-39/149/0', 'https://api.pota.app/park/grids/-39/113/-11/155/0']
    urls.each do |url|
      data = JSON.parse(open(url).read)
      next unless data
      puts 'Found ' + data['features'].count.to_s + ' parks'
      data['features'].each do |feature|
        is_invalid = false
        properties = feature['properties']
        geometry = feature['geometry']
        puts properties.to_json
        ref = properties['reference']
        if ref[0..1]=='AU'
          p = Asset.find_by(code: properties['reference'])
          new = false
          unless p
            p = Asset.new
            new = true
            puts 'New park'
          else
            puts 'Existing POTA park'
          end
          if new == true or update == true then
            p.asset_type = 'pota park'
            p.code = properties['reference']
            p.safecode = p.get_safecode
            puts p.code
            p.name = properties['name']
            p.is_active = true
            p.url = 'assets/' + p.get_safecode
            puts p.name
            p.location = "POINT (#{geometry['coordinates'][0]} #{geometry['coordinates'][1]})"
            p.save
            if new then
               p.find_vk_capad_park
               p.reload
               p.find_vk_state_park if !p.boundary
            end
          end
        end
      end
    end
  end
  
  def Asset.export_llota(dxcc, filename)
    as = Asset.where(country: dxcc, asset_type: 'llota lake', is_active: true)

    headers = "reference_code, name, region, region_iso_code, longitude, latitude, grid_locator, description, access_info, info_url, is_active"

    rows = []
    as.each do |a|
      row = []
      row.push(a.code.gsub('LL-','-'))
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
            r=Road.find_by(id: rid)
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
            r=DocTrack.find_by(id: rid)
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
        access = "Accessible only via private land with landowner consent" 
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

  def Asset.import_wwff(dxcc = 'ZL', update = true)
    require 'csv'
    url = 'https://wwff.co/wwff-data/wwff_directory.csv'
    data = open(url).read
    fields = data.parse_csv
    values = CSV(data).read

    row_count=0
    values.each do |row|
      row_count+=1
      next if row_count==1
      next unless row[fields.index("dxcc")] == dxcc
      next unless row[fields.index("status")] == 'active'
      next if row[fields.index("reference")][0..5]=='Select'
      code = row[fields.index("reference")]
      name = row[fields.index("name")]
      next unless name && code
      puts 'Code: ' + code + ', name: ' + name
      p = Asset.find_by(code: code)
      new = false
      if p
        puts "Existing park #{code}"
      else
        puts row.to_json
        p = Asset.new
        new = true
      end
      if new or update then
        p.code = code.strip
        p.name = name.strip
        p.location = "POINT(#{row[fields.index('longitude')]} #{row[fields.index('latitude')]})"
        p.country = dxcc
        p.region = "OC / #{dxcc}"
        puts p.to_json
        p.save
        if new == true
          if p.country == 'ZL'
            p.find_zlota_park
            p.reload
          elsif p.country == 'VK'
            p.find_vk_capad_park
            p.reload
            p.find_vk_state_park if !p.boundary
          end
        else
          puts 'Existing WWFF park'
        end
        p.save
        next unless new
        #p.add_region
        #p.add_area
        #p.add_links
      end
    end
  end
   

  def Asset.import_llota(update = true)
    url = 'https://llota.app/api/public/references?version=lite'
    data = JSON.parse(open(url).read)
    if data
      puts 'Found ' + data.count.to_s + ' lakes'
      count = 0
      data.each do |l|
        if l["reference_code"][0..2]=='NZ-' or l["reference_code"][0..2]=='AU-'then
          count += 1
          new = false
          a = Asset.find_by(code: l["reference_code"].gsub('-','LL-'))
          if !a  
            puts "Creating #{l["reference_code"].gsub('-','LL-')}"
            a = Asset.new 
            new = true
          else
            puts "Updating #{a.code}"
          end
          if new or update then
            a.asset_type="llota lake"
            a.code = l["reference_code"].gsub('-','LL-')
            a2 = Asset.find_by(code: a.code.gsub('NZLL-','ZLL/'))
            if a2 then
              puts "Found matching lake #{a2.code}"
              a.description = a2.description
              a.boundary = a2.boundary
              a.is_active = a2.is_active
            end
            a.name = l["name"]
            a.location = "POINT(#{l["longitude"]} #{l["latitude"]})"
            a.save 
          end
        end
      end
    end
  end
        

  def Asset.add_parks
    ps = Park.find_by_sql ['select id from parks;']
    ps.each do |pid|
      p = Park.find_by_id(pid)
      a = Asset.find_by(asset_type: 'park', code: p.dist_code)
      a ||= Asset.find_by(asset_type: 'park', code: p.code)
      if !a
        a = Asset.new
        new = true
        logger.debug 'New'
      else
        new = false
      end
      a.asset_type = 'park'
      a.code = p.dist_code
      a.old_code = p.code
      if p.master_id
        cp = Crownpark.find_by_id(p.master_id)
        pp = Park.find_by_id(cp.napalis_id) if cp
        if pp
          a.master_code = pp.dist_code
        else
          logger.error 'ERROR: failed to find park ' + p.master_id.to_s + ' master for ' + p.dist_code + ' ' + p.name
          p.master_id = nil
          a.master_code = nil
        end
      end
      a.safecode = a.code.tr('/', '_')
      a.url = 'assets/' + a.safecode
      a.name = p.name.gsub("'", "''")
      a.description = (p.description || '').gsub("'", "''")
      (a.is_active = p.is_active) && !p.is_mr
      a.category = (p.owner || '').gsub("'", "''")
      a.location = p.location
      a.save if new
      ActiveRecord::Base.connection.execute("update assets set code='" + a.code + "', old_code='" + (a.old_code || '') + "',master_code='" + (a.master_code || '') + "', safecode='" + a.safecode + "', url='" + a.url + "', name='" + a.name + "', description='" + (a.description || '') + "', is_active=" + a.is_active.to_s + ", category='" + (a.category || '') + "', location=(select location from parks where id=" + p.id.to_s + '),  boundary=(select boundary from parks where id=' + p.id.to_s + ') where id=' + a.id.to_s + ';')
      a.post_save_acions
      logger.debug a.code
    end
    true
  end

  def Asset.add_huts
    ps = Hut.all
    ps.each do |p|
      a = Asset.find_by(asset_type: 'hut', code: p.code)
      a ||= Asset.new
      a.asset_type = 'hut'
      a.code = p.code
      a.url = '/huts/' + p.id.to_s
      a.name = p.name
      a.description = p.description
      a.is_active = p.is_active
      a.location = p.location
      a.altitude = p.altitude
      a.save
      logger.debug a.code
    end
    true
  end

  def Asset.add_islands
    ps = Island.all
    ps.each do |p|
      a = Asset.find_by(asset_type: 'island', code: p.code)
      a ||= Asset.new
      a.asset_type = 'island'
      a.code = p.code_dist
      a.old_code = p.code
      a.url = 'asset/' + a.code
      a.name = p.name
      a.description = p.info_description
      a.is_active = p.is_active
      a.location = p.WKT
      a.boundary = p.boundary
      a.save
      logger.debug a.code
    end
    true
  end

  def Asset.add_lakes
    ls = Lake.where(is_active: true)
    ls.each do |l|
      Asset.add_lake(l)
    end
  end

  def Asset.add_lake(l)
    a = Asset.find_by(asset_type: 'lake', code: l.code)
    unless a
      a = Asset.new
      logger.debug 'New'
    end
    a.asset_type = 'lake'
    a.code = l.code
    a.safecode = a.code.tr('/', '_')
    a.url = '/assets/' + a.safecode
    a.is_active = true
    a.name = l.name
    a.location = l.location
    a.boundary = l.boundary
    a.ref_id = l.topo50_fid
    a.save
    logger.debug a.code
    a
  end

  def Asset.add_sota_peak(p)
    a = Asset.find_by(asset_type: 'summit', code: p.summit_code)
    unless a
      logger.debug 'New peak: ' + p.summit_code
      a = Asset.new
    end
    a.asset_type = 'summit'
    a.code = p.summit_code
    a.safecode = a.code.tr('/', '_')
    a.is_active = true
    a.name = p.name
    a.location = p.location
    a.points = p.points
    a.altitude = p.alt
    if p.valid_to != '0001-01-01 00:00:00'
      logger.debug 'retured summit: ' + a.code
      a.valid_to = p.valid_to
    else
      a.valid_to = nil
    end
    a.valid_from = p.valid_from if p.valid_from != '0001-01-01 00:00:00'
    if a.changed? && (a.changed - ['valid_from']).count.positive?
      logger.debug'Changed: ' + a.changed.to_json
      a.save
      logger.debug 'Create/Updated: ' + a.code
    end
    a
  end

  def Asset.add_pota_parks
    ps = PotaPark.all
    ps.each do |p|
      Asset.add_pota_park(p)
    end
  end

  def Asset.add_pota_park(p, existing_asset)
    a = Asset.find_by(asset_type: 'pota park', code: p.reference)
    a ||= Asset.new
    a.asset_type = 'pota park'
    a.code = p.reference
    a.safecode = p.reference.tr('/', '_')
    a.is_active = true
    if a.id && ((a.name != p.name) || (a.location != p.location))
      logger.warn 'Exiting asset needs updating'
      name = p.name.gsub("'", "''")
      if existing_asset
        ActiveRecord::Base.connection.execute("update assets set code='" + p.reference + "', name='" + name + "', is_active=true, location=ST_GeomFromText('POINT(#{p.location.x} #{p.location.y})',4326), boundary=(select boundary from assets where id=" + existing_asset.id.to_s + ') where id=' + a.id.to_s + ';')
      else
        ActiveRecord::Base.connection.execute("update assets set code='" + p.reference + "', name='" + name + "', is_active=true, location=ST_GeomFromText('POINT(#{p.location.x} #{p.location.y})',4326) where id=" + a.id.to_s + ';')
      end
    elsif !a.id
      logger.debug 'Adding data to new asset'
      a.name = p.name
      a.location = p.location
      a.save
      if existing_asset
        ActiveRecord::Base.connection.execute('update assets set boundary=(select boundary from assets where id=' + existing_asset.id.to_s + ') where id=' + a.id.to_s + ';')
        a.post_save_actions
      end
    end

    logger.debug a.code
    a
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

  def Asset.add_wwff_parks
    ps = WwffPark.all
    ps.each do |p|
      Asset.add_wwff_park(p, nil)
    end
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

  def Asset.add_wwff_park(p, existing_asset)
    a = Asset.find_by(asset_type: 'wwff park', code: p.code)
    a ||= Asset.new
    a.asset_type = 'wwff park'
    a.code = p.code
    a.is_active = true

    if a.id && ((a.name != p.name) || (a.location != p.location))
      logger.debug 'Exiting asset needs updating'
      name = p.name.gsub("'", "''")
      if existing_asset
        ActiveRecord::Base.connection.execute("update assets set code='" + p.code + "', name='" + name + "', is_active=true, location=ST_GeomFromText('POINT(#{p.location.x} #{p.location.y})',4326), boundary=(select boundary from assets where id=" + existing_asset.id.to_s + ') where id=' + a.id.to_s + ';')
      else
        ActiveRecord::Base.connection.execute("update assets set code='" + p.code + "', name='" + name + "', is_active=true, location=ST_GeomFromText('POINT(#{p.location.x} #{p.location.y})',4326) where id=" + a.id.to_s + ';')
      end
    elsif !a.id
      logger.debug 'Adding data to new asset'
      a.name = p.name
      a.location = p.location
      a.save
      if existing_asset
        ActiveRecord::Base.connection.execute('update assets set boundary=(select boundary from assets where id=' + existing_asset.id.to_s + ') where id=' + a.id.to_s + ';')
        a.post_save_actions
      end
    end
    logger.debug a.code
    a
  end

  def find_zlota_park
    # p.location='POINT('+feature["Longitude"].to_s+' '+feature["Latitude"].to_s+')'
    # try to match against park
    searchname = name.gsub("'", "''")
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
      id = nil
      if zps && (zps.count > 1)
        puts '==========================================================='
        count = 0
        zps.each do |pp|
          puts count.to_s + ' - ' + pp.name + ' == ' + self.name
          count += 1
        end
        puts "Select match (or 'a' to skip):"
        id = gets
        zps = [zps[id.to_i]] if id && (id.length > 1) && (id[0] != 'a')
      end
    end
    if !zps || zps.count.zero? || (id && id[0] == 'a')
      puts 'enter asset id to match: '
      code = gets
      zps = Asset.where(code: code.strip)
    end

    if zps && (zps.count == 1)
      park = zps.first
      location = park.location
      puts "Matched #{name} with #{park.name}"
    else
      puts 'Could not find match. No location'
    end
  end 

  def find_vk_capad_park
   if !self.name.include?("Beach") and !self.name.include?("Wild and Scenic River")
    found=false
    shortname = self.name.gsub(" B.R.","").gsub(" N.C.R.","").gsub(" SS.R.","").gsub(" F.R.","").gsub(" B.R","")
    if self.old_code and self.old_code>0 then
      cs = Capad.find_by_sql [ %q{select "objectid", ST_Buffer(ST_Simplify("wkb_geometry",0.0002),0) as "wkb_geometry", "pa_id", "pa_pid", "name", "capad_type", "type_abbr", "iucn", "nrs_pa", "nrs_mpa", "gaz_area", "gis_area", "gaz_date", "latest_gaz", "state", "authority", "datasource", "governance", "comments", "environ", "overlap", "mgt_plan", "res_number", "zone_type", "epbc", "longitude", "latitude", "pa_system", "shape_leng", "shape_area" from capad where objectid = }+self.old_code.to_s+%q{;} ]
      if cs and cs.count>0 then
        self.boundary = cs.first.wkb_geometry.to_s.gsub("POLYGON ","MULTIPOLYGON (")+")"
        self.save
        puts self.code
        found = true
      else
        puts "Has id but no boundary!  Why?: "+self.code
      end
    end
    if found==false
     cs = Capad.find_by_sql [ %q{select distinct "wkb_geometry", "pa_id", "pa_pid", "name", "capad_type", "type_abbr", "iucn", "nrs_pa", "nrs_mpa", "gaz_area", "gis_area", "gaz_date", "latest_gaz", "state", "authority", "datasource", "governance", "comments", "environ", "overlap", "mgt_plan", "res_number", "zone_type", "epbc", "longitude", "latitude", "pa_system", "shape_leng", "shape_area" from capad where st_within ( st_geomfromtext('}+self.location.to_s+%q{', 4326), wkb_geometry);} ]
     if cs and cs.count>0 then
       cs = Capad.find_by_sql [ %q{select "objectid", ST_Buffer(ST_Simplify("wkb_geometry",0.0002),0) as "wkb_geometry", "pa_id", "pa_pid", "name", "capad_type", "type_abbr", "iucn", "nrs_pa", "nrs_mpa", "gaz_area", "gis_area", "gaz_date", "latest_gaz", "state", "authority", "datasource", "governance", "comments", "environ", "overlap", "mgt_plan", "res_number", "zone_type", "epbc", "longitude", "latitude", "pa_system", "shape_leng", "shape_area" from capad where st_within ( st_geomfromtext('}+self.location.to_s+%q{', 4326), wkb_geometry);} ]
       found = false
       cs.each do |c|
         c_shortname = c.name.gsub(" B.R.","").gsub(" N.C.R.","").gsub( "N.C.R","").gsub(" SS.R.","").gsub(" SS.R","").gsub(" F.R.","").gsub(" F.R","").gsub(" B.R","").gsub(" S.R.","").gsub(" S.R","").gsub(" F.F.R.","").gsub(" F.F.R","").gsub(" G.R.","").gsub(" G.R","").gsub(" W.R.","").gsub(" W.R","").gsub(" N.F.S.R.","").gsub(" N.F.S.R","").gsub(" G.L.R.","").gsub(" G.L.R","").gsub(" N.F.R.","").gsub(" N.F.R","")

         if found==false and ((shortname == c_shortname) or (shortname == c_shortname+" "+c.capad_type) or (shortname == (c_shortname+" "+c.capad_type)[0..shortname.length-1]) or (shortname[0..c_shortname.length-1] == (c_shortname))) then
           self.old_code = c.objectid
           capads = Capad.find_by_sql [ %q{select ST_Multi(ST_Buffer(ST_Simplify(st_union("wkb_geometry"),0.0002),0)) as "wkb_geometry" from capad where objectid = }+c.objectid.to_s ]
           self.boundary = capads.first.wkb_geometry
           self.save
           puts "assigned "+c.name+" to "+self.name
           found = true
         end
       end
       if found == false then
         puts "Asset: "+self.name+" ("+shortname+")"
         count=0
         puts "Found: "
         cs.each do |c| puts (count=count+1).to_s+" "+c.name+" "+c.objectid.to_s+" Area: "+c.shape_area.to_s; end
         puts "Select match number or enter to skip:"
         id = gets
         if id.to_i>0 then
            c=cs[id.to_i-1]
            self.old_code = c.objectid
            capads = Capad.find_by_sql [ %q{select ST_Multi(ST_Buffer(ST_Simplify(st_union("wkb_geometry"),0.0002),0)) as "wkb_geometry" from capad where objectid = }+c.objectid.to_s ]
            self.boundary = capads.first.wkb_geometry
            self.save
            puts "assigned "+c.name+" to "+self.name
         end
       end
     elsif cs and cs.count == 1 then
        cs = Capad.find_by_sql [ %q{select "objectid", ST_Buffer(ST_Simplify("wkb_geometry",0.0002),0) as "wkb_geometry", "pa_id", "pa_pid", "name", "capad_type", "type_abbr", "iucn", "nrs_pa", "nrs_mpa", "gaz_area", "gis_area", "gaz_date", "latest_gaz", "state", "authority", "datasource", "governance", "comments", "environ", "overlap", "mgt_plan", "res_number", "zone_type", "epbc", "longitude", "latitude", "pa_system", "shape_leng", "shape_area" from capad where st_within ( st_geomfromtext('}+self.location.to_s+%q{', 4326), wkb_geometry) limit 1;} ]
       if (shortname == cs.first.name) or (shortname == cs.first.name+" "+cs.first.capad_type) or (shortname == (cs.first.name+" "+cs.first.capad_type)[0..shortname.length-1])then
         puts "Found: "+self.name+" = "+cs.first.name+" "+cs.first.capad_type
         self.old_code = cs.first.objectid
         capads = Capad.find_by_sql [ %q{select ST_Multi(ST_Buffer(ST_Simplify(st_union("wkb_geometry"),0.0002),0)) as "wkb_geometry" from capad where objectid = }+cs.first.objectid.to_s ]
         self.boundary = capads.first.wkb_geometry
         self.save
       else
         puts "Does not match, use anyway (N/y): "+self.name+" = "+cs.first.name+" "+cs.first.capad_type
         id = gets
         if (id[0] == 'y')  then
           self.old_code = cs.first.objectid
           capads = Capad.find_by_sql [ %q{select ST_Multi(ST_Buffer(ST_Simplify(st_union("wkb_geometry"),0.0002),0)) as "wkb_geometry" from capad where objectid = }+cs.first.objectid.to_s ]
           self.boundary = capads.first.wkb_geometry
           self.save
         end
      end
     else
      puts "NO MATCH FOUND for "+self.name
     end
    end
    cs
   end
  end

  def find_vk_state_park
    sps = VkStatePark.find_by_sql [ %q{select * from vk_state_park where st_within ( st_geomfromtext('}+self.location.to_s+%q{', 4326), boundary);} ]

    if sps and sps.count == 1 then
        found = false
        spsname = (sps.first.name || "").upcase.gsub(/[^A-Z0-9 ]/, '')
        ourname = (self.name.upcase || "").gsub(/[^A-Z0-9 ]/, '')
        if spsname.split(" ").sort == ourname.split(" ").sort  then
          found=true
        else
          puts "Does not match, use anyway (N/y): "+self.name+" = "+(sps.first.name || "")
          id = gets
          if (id[0] == 'y')  then
            found = true
          end
        end
        if found == true
          puts "#{self.name} == #{sps.first.unique_name}"
          self.boundary = sps.first.boundary.to_s
          self.old_code = sps.first.unique_name
          self.save
          found = true
        end
      elsif sps.count == 0
        puts "Not found #{self.name}"
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
            self.boundary = sp.first.boundary
            self.save
            puts "assigned "+c.name+" to "+self.name
         end
      end
      self.add_simple_boundary
  end


end
