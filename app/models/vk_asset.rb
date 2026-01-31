# typed: false
class VkAsset < ActiveRecord::Base
  before_validation { assign_calculated_fields }
  def assign_calculated_fields
    at = AssetType.find_by(pnp_class: self.award)
    self.asset_type = at.name if at
  end

  # fake ZL asset fields
  def get_url
    'vkassets/' + get_safecode
  end

  def minor
    false
  end

  def x
   location.x if location
  end

  def y
   location.y if location
  end

  def maidenhead
    if location
      mhl = '######'
      abc = 'abcdefghijklmnopqrstuvwxyz'
      lat = location.y
      long = location.x
      long += 180
      lat += 90

      long20 = (long / 20).to_i
      lat10 = (lat / 10).to_i
      long2 = ((long - (long20 * 20)) / 2).to_i
      lat1 = (lat - (lat10 * 10)).to_i
      longm = ((long - (long20 * 20 + long2 * 2)) * 12).to_i
      latm = ((lat - (lat10 * 10 + lat1)) * 24).to_i
      mhl[0] = abc[long20].upcase
      mhl[1] = abc[lat10].upcase
      mhl[2] = long2.to_s
      mhl[3] = lat1.to_s
      mhl[4] = abc[longm]
      mhl[5] = abc[latm]
    else
      mhl = ''
    end
    mhl
  end


  def type
    type = AssetType.find_by(name: asset_type)
    type ||= AssetType.find_by(name: 'all')
    type

  end

  def self.import_siota
    require 'csv'
    url = "https://www.silosontheair.com/data/silos.csv"
    data = open(url).read
    fields = data.parse_csv
    values = CSV(data).read
   
    rowcount = 0
    values.each do |silo|
      if rowcount!=0
        code = silo[fields.index("SILO_CODE")] 
        asset = VkAsset.find_by(code: code)
        description = silo[fields.index("COMMENT")]
        ase_desc = ""
        asc_desc = description.force_encoding("ISO-8859-1") if description
        if !asset then 
          asset = VkAsset.new
          puts "New Silo"
        end
        puts code
        asset.location="POINT (#{silo[fields.index("LNG")]} #{silo[fields.index("LAT")]})"
        asset.name=silo[fields.index("NAME")]
        asset.code=code
        asset.state=silo[fields.index("STATE")]
        asset.description=asc_desc
        asset.is_active=true
        asset.award='SiOTA'
        asset.asset_type="silo"
        asset.url = 'vkassets/' + asset.get_safecode
        puts asset.to_json
        asset.save
      end
      rowcount+=1
    end 
  end

  #run this to get the VKFF and associated POTA
  def self.import
    destroy_all
    url = 'http://parksnpeaks.org/api/SITES'
    data = JSON.parse(open(url).read)
    if data
      data.each do |site|
        next unless site && site['ID'] && ((site['ID'][0..1] == 'VK') || (site['ID'][0..1] == 'AU')) && (site['ID'].length > 4)
        p = VkAsset.find_by(code: site['ID'])
        method = "Updating "
        if !p then
          p = VkAsset.new
          method = "Adding "
        end
        p.award = site['Award']
        p.wwff_code = site['Location']
        p.shire_code = site['ShireID']
        p.code = site['ID']
        p.wwff_code = p.code if p.code[0..3] == 'VKFF'
        p.name = site['Name']
        p.site_type = site['Type']
        p.latitude = site['Latitude']
        p.longitude = site['Longitude']
        p.location = 'POINT(' + p.longitude.to_s + ' ' + p.latitude.to_s + ')'
        p.is_active = true
        p.url = 'vkassets/' + get_safecode
        puts method + ' ' + p.code + ' [' + p.name + ']'
        if p.wwff_code
          detailurl = 'http://parksnpeaks.org/api/PARK/WWFF/' + p.wwff_code
          ddraw = open(detailurl).read
          if ddraw["Failed to connect"] then
            puts "Error connecting to PnP"
            ddraw = open(detailurl).read
            if ddraw["Failed to connect"] then
              puts "Feiled 2nd try, aborting"
              ddraw = nil
            end
          end 
          detaildata = ddraw && (ddraw.length > 2) ? JSON.parse(ddraw) : nil
          if detaildata
            p.pota_code = detaildata[0]['POTAID']
            p.state = detaildata[0]['State']
            p.region = detaildata[0]['Region']
            p.district = detaildata[0]['District']
          end
        end
        p.save
      end
    end
  end

  #then run this to create POTA parks from dual WWFF-POTA entities
  def self.add_pota_parks
    assets = VkAsset.find_by_sql [" select * from vk_assets where award='WWFF' and pota_code is not null "]
    assets.each do |asset|
      va = asset.dup
      va.code = va.pota_code
      puts va.code
      va.award = 'POTA'
      va.save
    end
  end
  
  #then run this to get POTA-only parks
  def self.import_missing_pota(create = true)
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
          p = VkAsset.find_by(code: properties['reference'])
          new = false
          unless p
            p = VkAsset.new
            new = true
            puts 'New park'
          end
          p.award='POTA'
          p.pota_code = properties['reference']
          puts p.code
          p.code = properties['reference']
          p.name = properties['name']
          p.is_active = true
          p.url = 'vkassets/' + get_safecode
          puts p.name
          p.location = "POINT (#{geometry['coordinates'][0]} #{geometry['coordinates'][1]})"
          p.save
        else
          puts 'Existing POTA park'
        end
      end
    end 
  end

  def find_pota_park_from_wwff
    if self.award == 'POTA' and self.wwff_code and self.wwff_code != self.code then
      puts "Assigning #{self.code} from #{self.wwff_code}"
      w = VkAsset.find_by(code: self.wwff_code)
      puts w.to_s
      self.boundary = w.boundary
      self.caped_id = w.caped_id
      self.save 
    end
  end

  def find_capad_park
   if !self.name.include?("Beach")
    found=false
    shortname = self.name.gsub(" B.R.","").gsub(" N.C.R.","").gsub(" SS.R.","").gsub(" F.R.","").gsub(" B.R","")
    if self.caped_id and self.caped_id>0 then
      cs = Capad.find_by_sql [ %q{select "objectid", ST_Buffer(ST_Simplify("wkb_geometry",0.0002),0) as "wkb_geometry", "pa_id", "pa_pid", "name", "capad_type", "type_abbr", "iucn", "nrs_pa", "nrs_mpa", "gaz_area", "gis_area", "gaz_date", "latest_gaz", "state", "authority", "datasource", "governance", "comments", "environ", "overlap", "mgt_plan", "res_number", "zone_type", "epbc", "longitude", "latitude", "pa_system", "shape_leng", "shape_area" from capad where objectid = }+self.caped_id.to_s+%q{;} ]
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
           self.caped_id = c.objectid
           self.boundary = c.wkb_geometry.to_s.gsub("POLYGON ","MULTIPOLYGON (")+")"
           self.save
           puts "assigned "+c.name+" to "+self.name
           found = true
         end
       end
       if found == false then 
         puts "Asset: "+self.name+" ("+shortname+")"
         count=0
         puts "Found: "
         cs.each do |c| puts (count=count+1).to_s+" "+c.name; end
         puts "Select match number or enter to skip:"
         id = gets
         if id.to_i>0 then
            c=cs[id.to_i-1]
            self.caped_id = c.objectid
            self.boundary = c.wkb_geometry.to_s.gsub("POLYGON ","MULTIPOLYGON (")+")"
            self.save
            puts "assigned "+c.name+" to "+self.name
         end
       end
     elsif cs and cs.count == 1 then
        cs = Capad.find_by_sql [ %q{select "objectid", ST_Buffer(ST_Simplify("wkb_geometry",0.0002),0) as "wkb_geometry", "pa_id", "pa_pid", "name", "capad_type", "type_abbr", "iucn", "nrs_pa", "nrs_mpa", "gaz_area", "gis_area", "gaz_date", "latest_gaz", "state", "authority", "datasource", "governance", "comments", "environ", "overlap", "mgt_plan", "res_number", "zone_type", "epbc", "longitude", "latitude", "pa_system", "shape_leng", "shape_area" from capad where st_within ( st_geomfromtext('}+self.location.to_s+%q{', 4326), wkb_geometry) limit 1;} ]
       if (shortname == cs.first.name) or (shortname == cs.first.name+" "+cs.first.capad_type) or (shortname == (cs.first.name+" "+cs.first.capad_type)[0..shortname.length-1])then
         puts "Found: "+self.name+" = "+cs.first.name+" "+cs.first.capad_type
         self.caped_id = cs.first.objectid
         self.boundary = cs.first.wkb_geometry.to_s.gsub("POLYGON ","MULTIPOLYGON (")+")"
         self.save
       else
         puts "Does not match, use anyway (N/y): "+self.name+" = "+cs.first.name+" "+cs.first.capad_type 
         id = gets
         if (id[0] == 'y')  then
           self.caped_id = cs.first.objectid
           self.boundary = cs.first.wkb_geometry.to_s.gsub("POLYGON ","MULTIPOLYGON (")+")"
           self.save
         end
      end
     end
    end
    cs
   end
  end

  def add_simple_boundary
    if boundary
      ActiveRecord::Base.connection.execute('update vk_assets set boundary_simplified=ST_Simplify("boundary",0.002) where id=' + id.to_s + ';')
      ActiveRecord::Base.connection.execute('update vk_assets set boundary_very_simplified=ST_Simplify("boundary",0.02) where id=' + id.to_s + ';')
      ActiveRecord::Base.connection.execute('update vk_assets set boundary_quite_simplified=ST_Simplify("boundary",0.002) where id=' + id.to_s + ';')
    end
  end

  def get_safecode
    code.tr('/', '_')
  end

  # add areas for all assets
  # Calculate area of the asset
  def add_area
      asset_test = VkAsset.find_by_sql [" select (boundary is not null) as has_boundary from vk_assets where id=#{id}"]
      if asset_test.first.has_boundary == true
        ActiveRecord::Base.connection.execute(' update vk_assets set area=ST_Area(geography(boundary)) where id=' + id.to_s)
      end
  end

  def external_url
    url = if award == 'HEMA'
            'https://parksnpeaks.org/showAward.php?award=HEMA'
          elsif award == 'SiOTA'
            'https://www.silosontheair.com/silos/#' + code.to_s
          elsif award == 'POTA'
            'https://pota.app/#/park/' + code.to_s
          elsif award == 'SOTA'
            'https://summits.sota.org.uk/summit/' + code.to_s
          elsif award == 'WWFF'
            'https://parksnpeaks.org/getPark.php?actPark=' + code.to_s + '&submit=Process'
          else
            '/assets'
          end
    url
  end

  def codename
    '[' + code + '] ' + name
  end

  def wwff_asset
    asset = nil
    if award != 'WWFF'
      asset = VkAsset.find_by(code: wwff_code) if wwff_code && !wwff_code.empty?
    end
    asset
  end

  def pota_asset
    asset = nil
    if award != 'POTA'
      if pota_code && !pota_code.empty?
        asset = VkAsset.find_by(code: pota_code)
        if asset
          asset.award = 'POTA'
          asset.code = pota_code
        end
      end
    end
    asset
  end

  def contained_by_assets
    assets = []
    assets.push(pota_asset) if pota_asset
    assets.push(wwff_asset) if wwff_asset
    assets
  end

  def contains_assets
    assets = []

    if award == 'WWFF'
      assets = VkAsset.where(wwff_code: code)
    elsif award == 'POTA'
      assets = VkAsset.where(pota_code: code)
    end
    assets
  end

  def self.containing_codes_from_parent(code)
    codes = []
    code = code.upcase
    a = VkAsset.find_by(code: code.split(' ')[0])

    codes = a.contained_by_assets.map(&:code) if a
    codes
  end

  # simplified boundary with downscaling big assets (and detail/accuracy for small assets)
  def boundary_simple
    pp = VkAsset.find_by_sql ['select id, ST_NPoints(boundary) as numpoints from vk_assets where id=' + id.to_s]
    if pp
      lenfactor = Math.sqrt((pp.first['numpoints'] || 0) / 10_000)
      rnd = 0.000002 * 10**lenfactor
      boundarys = VkAsset.find_by_sql ['select id, ST_AsText(ST_Simplify("boundary", ' + rnd.to_s + ')) as "boundary" from vk_assets where id=' + id.to_s]
      boundary = boundarys.first.boundary
      boundary
    end
  end

end
