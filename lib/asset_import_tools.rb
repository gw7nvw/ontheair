# frozen_string_literal: true

# typed: false
module AssetImportTools
  def Asset.import_vk_pota(update = true, redraw = false, silent=false, resume_at = nil)
    need_resume = true if resume_at != nil
    urls = ['https://api.pota.app/park/grids/-43/143/-39/149/0', 'https://api.pota.app/park/grids/-39/113/-11/155/0']
    urls.each do |url|
      data = JSON.parse(open(url).read)
      next unless data
      puts 'Found ' + data['features'].count.to_s + ' parks'
      features = data['features']
      features = features.sort_by { |f| f['properties']['reference']}
      features.each do |feature|
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
                p.location = "POINT (#{geometry['coordinates'][0]} #{geometry['coordinates'][1]})"
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
                  p.old_code = nil
                  p.save 
                
                  p.find_vk_capad_park(silent)
                  p.reload
                  p.find_vk_state_park(silent)if !p.boundary
                end
              else
                #just save
                p.save
              end
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
    dxcc_len=dxcc.length-1
    url = "https://www.sotadata.org.uk/summitslist.csv"

    data = open(url).read
    data = "SummitCode"+data.split('SummitCode')[1]
    fields = data.parse_csv
    values = CSV(data).read
    rowcount = 0
    values.each do |s|
      if rowcount!=0
        new = false
        code = s[fields.index("SummitCode")]
        if code[0..dxcc_len]==dxcc
          a=Asset.find_by(code: code)
          if !a then
            a=Asset.new
            puts "NEW SUMMIT #{code}"
            new = true
            a.code = code
            a.asset_type='summit'
            a.country 
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
            a.save
            a.reload
            if a.country == 'VK' and loc_change
             a.add_vk_sota_actvation_zone(25)
            end 
          end
        end
      end
      rowcount+=1
    end
  end

  def Asset.import_siota
    require 'csv'
    url = "https://www.silosontheair.com/data/silos.csv"
    data = open(url).read
    fields = data.parse_csv
    values = CSV(data).read

    rowcount = 0
    values.each do |silo|
      if rowcount!=0
        code = silo[fields.index("SILO_CODE")]
        asset = Asset.find_by(code: code)
        description = silo[fields.index("COMMENT")]
        ase_desc = ""
        asc_desc = description.force_encoding("ISO-8859-1") if description
        if !asset then
          asset = Asset.new
          puts "New Silo"
        end
        puts code
        asset.location="POINT (#{silo[fields.index("LNG")]} #{silo[fields.index("LAT")]})"
        asset.name=silo[fields.index("NAME")]
        asset.code=code
        asset.state=nil
        asset.country='VK'
        asset.description=asc_desc
        asset.valid_from = silo[fields.index("NOT_BEFORE")]
        asset.valid_to = silo[fields.index("NOT_AFTER")]
        if asset.valid_to == nil then 
          asset.is_active=true
        else
          asset.is_active=false
        end
        asset.asset_type="silo"
        asset.url = 'assets/' + asset.get_safecode
        puts asset.to_json
        asset.save
      end
      rowcount+=1
    end
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
  def Asset.import_wwff(dxcc = 'ZL', update = false, redraw = false, start="", theend="zzzz")
    require 'csv'
    url = 'https://wwff.co/wwff-data/wwff_directory.csv'
    data = open(url).read
    fields = data.parse_csv
    values = CSV(data).read

    row_count=0
    values.each do |row|
      row_count+=1
      next if row_count==1  or row[fields.index("reference")]<start or row[fields.index("reference")]>theend
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
        puts "NEW"
        puts row.to_json
        p = Asset.new
        new = true
      end
      if new or update then
        p.code = code.strip
        p.name = name.strip
        p.country = dxcc
        p.asset_type='wwff park'
        p.valid_from = row[fields.index("validFrom")] if row[fields.index("validFrom")]!="0000-00-00" and row[fields.index("validFrom")]!=nil
        p.valid_to = row[fields.index("validTo")].to_datetime if row[fields.index("validTo")]!="0000-00-00" and row[fields.index("validTo")]!=nil
        if (!p.valid_to and row[fields.index("validTo")]!="0000-00-00") and row[fields.index("status")] == 'active'
          p.is_active = true
        else
          p.is_active = false
        end
        p.save
        if new == true or redraw==true
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
          p.save
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
      end
    end
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
    url = 'https://llota.app/api/public/references?version=lite'
    data = JSON.parse(open(url).read)
    if data
      puts 'Found ' + data.count.to_s + ' lakes'
      count = 0
      data.each do |l|
        if l["reference_code"][0..4]=='LL'+dxcc_filter+'-' then
          count += 1
          new = false
          a = Asset.find_by(code: l["reference_code"])
          if !a  
            puts "Creating #{l["reference_code"]}"
            a = Asset.new 
            new = true
          else
            puts "Updating #{a.code}"
          end
          if new or update then
            a.asset_type="llota lake"
            a.code = l["reference_code"]
            a.is_active = true
            if a.code[0..3]=='LLNZ'
              a2 = Asset.find_by(code: a.code.gsub('LLNZ-','ZLL/'))
              if a2 then
                puts "Found matching lake #{a2.code}"
                a.description = a2.description
                a.boundary = a2.boundary
                a.is_active = a2.is_active
              end
            end
            a.name = l["name"]
            a.location = "POINT(#{l["longitude"]} #{l["latitude"]})"
            dxcc = DxccPrefix.find_by("iso_code = ? and prefix in ('ZL', 'VK')",a.code[2..3])
            a.country = dxcc.prefix if dxcc
            a.save 
          end
          if (a.boundary == nil or force == true)  and a.country=='VK'
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
              if !lake and silent == false then
                puts "Select match (or 'a' to skip):"
                id = gets
                lake = [lakes[id.to_i]] if id && (id.length > 1) && (id[0] != 'a')
              end
            end
 
            
            if lake   
               puts "Matching #{a.name} with #{lake.name}"
               a.boundary = lake.wkb_geometry
               a.save
            else
               puts "ERROR: NOT FOUND !!!!!!!!!!#{ a.name} !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
               a.save
            end
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
    new = false
    unless a
      a = Asset.new
      new = true
      logger.debug 'New'
    end
    a.asset_type = 'lake'
    a.code = l.code
    a.safecode = a.code.tr('/', '_')
    a.url = '/assets/' + a.safecode
    a.is_active = true
    a.name = l.name
    a.location = l.location if new
    a.boundary = l.boundary if new
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
end

class Asset
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


  def find_vk_capad_park(ignore=false)
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
     elsif cs and cs.count == 1 then
        cs = Capad.find_by_sql [ %q{select "objectid", ST_Buffer(ST_Simplify("wkb_geometry",0.0002),0) as "wkb_geometry", "pa_id", "pa_pid", "name", "capad_type", "type_abbr", "iucn", "nrs_pa", "nrs_mpa", "gaz_area", "gis_area", "gaz_date", "latest_gaz", "state", "authority", "datasource", "governance", "comments", "environ", "overlap", "mgt_plan", "res_number", "zone_type", "epbc", "longitude", "latitude", "pa_system", "shape_leng", "shape_area" from capad where st_within ( st_geomfromtext('}+self.location.to_s+%q{', 4326), wkb_geometry) limit 1;} ]
       if (shortname == cs.first.name) or (shortname == cs.first.name+" "+cs.first.capad_type) or (shortname == (cs.first.name+" "+cs.first.capad_type)[0..shortname.length-1])then
         puts "Found: "+self.name+" = "+cs.first.name+" "+cs.first.capad_type
         self.old_code = cs.first.pa_id
         self.boundary = get_capad_boundary(cs.first.pa_id)
         self.save
       else
         if ignore == true then
           puts "WARNING: ignoring this park which requires user selection"
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
  
  def capad_expand_abbreviations(name)
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

  def get_capad_boundary(pa_id)
    capad = nil
    capads = Capad.find_by_sql [ %Q{ select ST_Multi(ST_Buffer(ST_Simplify(st_union("wkb_geometry"),0.0002),0)) as "wkb_geometry" from capad where pa_id ='#{pa_id}' group by pa_id} ]
    capad = capads.first.wkb_geometry if capads
    capad
  end

  def get_state_park_boundary(unique_name)
    capad = nil
    capads = VkStatePark.find_by_sql [ "select ST_Multi(ST_Union(boundary)) as boundary from vk_state_park where unique_name='#{unique_name.gsub("'","''")}' group by unique_name" ]
    capad = capads.first.boundary if capads
    capad
  end

  def find_vk_state_park(ignore=false)
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

  def add_govt_parks
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

