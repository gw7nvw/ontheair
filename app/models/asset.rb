class Asset < ActiveRecord::Base
  include AssetGisTools
  include AssetConsoleTools

 validates :code, presence: true, uniqueness: true
 validates :name, presence: true
 before_validation { self.assign_calculated_fields }
 after_save {self.post_save_actions}

SIOTA_REGEX=/^VK-[a-zA-Z]{3}\d{1}/
POTA_REGEX=/^[a-zA-Z0-9]{1,2}-\d{4,5}/
WWFF_REGEX=/^\d{0,1}[a-zA-Z]{1,2}[fF]{2}-\d{4}/
SOTA_REGEX=/^\d{0,1}[a-zA-Z]{1,2}\d{0,1}\/[a-zA-Z]{2}-\d{3}/
HEMA_REGEX=/^\d{0,1}[a-zA-Z]{1,2}\d{0,1}\/H[a-zA-Z]{2}-\d{3}/

SOTA_ASSET_URL="https://www.sotadata.org.uk/en/summit/"
WWFF_ASSET_URL="https://wwff.co/directory/?showRef="
POTA_ASSET_URL="https://pota.app/#/park/"
HEMA_ASSET_URL="http://www.hema.org.uk/fullSummit.jsp?summitKey="
SIOTA_ASSET_URL='https://www.silosontheair.com/silos/#'

################################################################
# Pre- and Post save callbacks
################################################################

#After save (things that need an asset id, generally)
def post_save_actions
  #do this here rather then before save to keep it pure PostGIS - no slow RGeo
  self.add_area
  self.add_altitude
  self.add_activation_zone
  self.add_links
  self.add_simple_boundary
end

#After validation but before save
def assign_calculated_fields
  if !self.valid_from then self.valid_from=Time.new('1900-01-01') end
  if self.minor!=true then self.minor=false end

  if !self.district then self.district=self.add_district() end
  if !self.region then self.region=self.add_region() end

  if self.code==nil or self.code=="" then
    self.code=Asset.get_next_code(self.asset_type,self.region)
  end
  if self.safecode==nil or self.safecode=="" then
    self.safecode=self.code.gsub('/','_')
  end

  self.url='assets/'+self.safecode
end


def add_links(flush=true)
  if flush==true then
    las=AssetLink.where(:contained_code=> self.code)
    Rails.logger.warn "DEBUG: deleting #{las.count.to_s} old parent links"
    las.destroy_all
    las=AssetLink.where(:containing_code=> self.code)
    Rails.logger.warn "DEBUG: deleting #{las.count.to_s} old child links"
    las.destroy_all
  end

  if self.is_active then
    #check assets contained by us, then assets containign us
    ['we are contained by', 'we contain'].each do |link_type|
      if link_type=='we are contained by' then 
        within_query="ST_Within(a.location, b.boundary)"
        area_query="b.area>a.area*0.9"
      else
        within_query="ST_Within(b.location, a.boundary)"
        area_query="a.area>b.area*0.9"
      end
      linked_assets=Asset.find_by_sql [ "
        select b.code as code, at.has_boundary as has_boundary, b.area as area 
          from assets a 
        inner join assets b 
          on b.is_active=true and "+within_query+" 
        inner join asset_types at 
          on at.name=b.asset_type  
        where 
          b.id!=a.id 
          and (b.area is null or "+area_query+") 
          and a.id = "+self.id.to_s
      ]
      logger.debug self.code+" might "+link_type+" "+linked_assets.to_json
      linked_assets.each do |linked_asset|
        matched=false

        #get the parameters the right way round for containing vs contained
        if link_type=='we contain' then
          contained_asset_code=linked_asset['code']; containing_asset_code=self.code
        else
          containing_asset_code=linked_asset['code']; contained_asset_code=self.code
        end
        #for polygon assets, ensure >=90% overlap
        if self.type.has_boundary and self.area and self.area>0 and linked_asset['has_boundary'] and linked_asset['area'] then
          overlap=ActiveRecord::Base.connection.execute( " select ST_Area(ST_intersection(a.boundary, b.boundary)) as overlap, ST_Area(b.boundary) as area from assets a join assets b on b.code='#{contained_asset_code}' where a.code='#{containing_asset_code}'; ")
          prop_overlap=overlap.first["overlap"].to_f/overlap.first["area"].to_f
          logger.debug "DEBUG: overlap #{prop_overlap.to_s} "+linked_asset['code']
          if prop_overlap>0.9 then 
            matched=true
          end

        #for point assets, accept point contained in polygon
        else
          matched=true
          logger.debug "DEBUG: Point: "+linked_asset['code']
        end

        #Fore all matched assets, if this combo does not already exist, create it
        if matched==true then
          logger.debug containing_asset_code+" contains "+contained_asset_code
          dup=AssetLink.where(:contained_code=> contained_asset_code, :containing_code => containing_asset_code)
          if (!dup or dup.count==0) and linked_asset['code']!=self.code then
            al=AssetLink.new
            al.contained_code=contained_asset_code
            al.containing_code=containing_asset_code
            al.save
          end
        end
      end #for linked assets
    end #for contained, containing
  end #if self.is_active
end

# add region - done directly in database so safe as an after-save callback
def add_region
  if self.location then region=Region.find_by_sql [ %q{select id, sota_code, name from regions where ST_Within(ST_GeomFromText('}+self.location.as_text+%q{', 4326), "boundary");} ] else logger.error "ERROR: place without location. Name: "+self.name+", id: "+self.id.to_s end
  if self.id and region and region.count>0 and self.region != region.first.sota_code then
    logger.debug "updating region to "+region.first.to_json
    ActiveRecord::Base.connection.execute("update assets set region='"+region.first.sota_code+"' where id="+self.id.to_s)
  end

  if region and region.count>0 and self.region != region.first.sota_code then
    return region.first.sota_code
  end
end

# add district - done directly in database so safe as an after-save callback
def add_district
  if self.location then district=District.find_by_sql [ %q{select id, district_code, name from districts where ST_Within(ST_GeomFromText('}+self.location.as_text+%q{', 4326), "boundary");} ] else logger.error "ERROR: place without location. Name: "+self.name+", id: "+self.id.to_s end
  if self.id and district and district.count>0 and self.district != district.first.district_code then
    ActiveRecord::Base.connection.execute("update assets set district='"+district.first.district_code+"' where id="+self.id.to_s)
  end

  if district and district.count>0 and self.district != district.first.district_code then
    return district.first.district_code
  end
end

#############################################################
# LINKED TABLES
#############################################################

#all photos for this asset
def photos
   ps=AssetPhotoLink.where(asset_code: self.code) 
end

#all contacts referring to this asset
def contacts
  contacts=Contact.find_by_sql [ "select * from contacts c where '"+self.code+"' = ANY(asset1_codes) or '"+self.code+"' = ANY(asset2_codes);" ]
end

#all logs referring to this asset
def logs
  logs=Log.find_by_sql [ "select * from logs l where '"+self.code+"' = ANY(asset_codes);" ]
end

#all web links for this asset
def web_links
  awl=AssetWebLink.where(asset_code: self.code)
end

#hutbagger page for this asset 
def hutbagger_link
  awl=AssetWebLink.find_by(asset_code: self.code, link_class: 'hutbagger')
end

#Returns string containing code and name: [<code>] <name
def codename
 "["+self.code+"] "+self.name
end

#AssetType
def type
  type=AssetType.find_by(name: self.asset_type)
  if !type then  type=AssetType.find_by(name: 'all') end
  type
end

# Traditional owners of land containing this asset.  
# if many, proide as comma-separated list
# If we are near the boundary, hedge our bets and say 'in or near'
def traditional_owners
  buffer=5000 #say in or near if we are withing this distance of boundary (meters)
  if self.type.has_boundary and self.area and self.area>0 then
     tos1=NzTribalLand.find_by_sql [ "select tl.id, tl.name, tl.ogc_fid from nz_tribal_lands tl join assets a on a.id=#{self.id} where ST_Within(a.boundary, tl.wkb_geometry) "]
     tos2=NzTribalLand.find_by_sql [ "select tl.id, tl.name, tl.ogc_fid from nz_tribal_lands tl join assets a on a.id=#{self.id} where ST_DWithin(ST_Transform(a.boundary,2193), ST_Transform(tl.wkb_geometry,2193), #{buffer});" ]
  else
     tos1=NzTribalLand.find_by_sql [ "select tl.id, tl.name, tl.ogc_fid from nz_tribal_lands tl join assets a on a.id=#{self.id} where ST_Within(a.location, tl.wkb_geometry) "]
     tos2=NzTribalLand.find_by_sql [ "select tl.id, tl.name, tl.ogc_fid from nz_tribal_lands tl join assets a on a.id=#{self.id} where ST_DWithin(ST_Transform(a.location,2193), ST_Transform(tl.wkb_geometry,2193), #{buffer});" ]

  end
  ids1=tos1.map{|t| t.id}
  ids2=tos2.map{|t| t.id}
  if ids2 and ids2.count>0 then
    if ids1.sort!=ids2.sort then
      names=[]; tos2.each do |t| names.push(t["name"]) end 
      trad_owners="In or near "+names.join(", ")+" country"
    else
      names=[]; tos1.each do |t| names.push(t["name"]) end 
      trad_owners=names.join(", ")+" country"
    end 
  else
    trad_owners=nil
  end 
  trad_owners
end

####################################################################
# Virtual calculated fields

def self.maidenhead_to_lat_lon(maidenhead)
  lat=180.0
  long=180.0
  maidenhead=maidenhead[0..5]
  #pad 4 digit maidenhead to 6
  if maidenhead.length==4 then maidenhead=maidenhead+"aa" end
  abc="abcdefghijklmnopqrstuvwxyz"
  long20=abc.upcase.index(maidenhead[0]).to_f
  lat10=abc.upcase.index(maidenhead[1]).to_f  
  long2=maidenhead[2].to_f
  lat1=maidenhead[3].to_f
  longm=abc.index(maidenhead[4]).to_f
  latm=abc.index(maidenhead[5]).to_f

  long=long20*20+long2*2+longm/12
  lat=lat10*10+lat1+latm/24
  long=long-180
  lat=lat-90
  location={x: long, y: lat}
end

# Return 6-digit maidenhead locator from location
def maidenhead
  if self.location then
    mhl="######"
    abc="abcdefghijklmnopqrstuvwxyz"
    lat=self.location.y
    long=self.location.x
    long=long+180
    lat=lat+90
  
    long20=(long/20).to_i
    lat10=(lat/10).to_i
    long2=((long-(long20*20))/2).to_i
    lat1=(lat-(lat10*10)).to_i
    longm=((long-(long20*20+long2*2))*12).to_i
    latm=((lat-(lat10*10+lat1))*24).to_i
    mhl[0]=abc[long20].upcase
    mhl[1]=abc[lat10].upcase
    mhl[2]=long2.to_s 
    mhl[3]=lat1.to_s 
    mhl[4]=abc[longm]
    mhl[5]=abc[latm]
  else
    mhl=""
  end
  mhl
end

# simplified boundary with downscaling big assets (and detail/accuracy for small assets)
def boundary_simple
   pp=Asset.find_by_sql [ "select id, ST_NPoints(boundary) as numpoints from assets where id="+self.id.to_s ]
   if pp then 
     lenfactor=Math.sqrt((pp.first['numpoints']||0)/10000)
     rnd=0.000002*10**lenfactor
     boundarys=Asset.find_by_sql [ 'select id, ST_AsText(ST_Simplify("boundary", '+rnd.to_s+')) as "boundary" from assets where id='+self.id.to_s ]  
     boundary=boundarys.first.boundary
     boundary
   else nil end
end

# name of distirct (without getting it's boundary)
def district_name
  name=""
  r=District.find_by(district_code: self.district)
  if r then r.name else "" end
end

# name of region (without getting it's boundary)
def region_name
  name=""
  r=Region.find_by(sota_code: self.region)
  if r then name=r.name.gsub('Region','') end
end

#NZTM coordinates: x
def x    
      if self.location
       fromproj4s= Projection.find_by_id(4326).proj4
       toproj4s=  Projection.find_by_id(2193).proj4

       fromproj=RGeo::CoordSys::Proj4.new(fromproj4s)
       toproj=RGeo::CoordSys::Proj4.new(toproj4s)

       xyarr=RGeo::CoordSys::Proj4::transform_coords(fromproj,toproj,self.location.x, self.location.y)
       xyarr[0]
     else nil end
end

#NZTM coordinates: y
def y
      if self.location
       fromproj4s= Projection.find_by_id(4326).proj4
       toproj4s=  Projection.find_by_id(2193).proj4

       fromproj=RGeo::CoordSys::Proj4.new(fromproj4s)
       toproj=RGeo::CoordSys::Proj4.new(toproj4s)

       xyarr=RGeo::CoordSys::Proj4::transform_coords(fromproj,toproj,self.location.x, self.location.y)
       xyarr[1]
     else nil end
end

def first_activated
 cs=Contact.find_by_sql [ ' select * from contacts where ? = ANY(asset1_codes) or ? = ANY(asset2_codes) order by date, time limit 1 ', self.code, self.code ]
 if cs and cs.count>0 then 
   c=cs.first 
   if c.asset2_codes.include?(self.code) then 
      c=c.reverse
   end
 else 
  c=nil 
 end

 if self.asset_type=="summit"  or self.asset_type=="pota park"then
   as=ExternalActivation.find_by_sql [ "select * from external_activations where summit_code='"+self.code+"' order by date asc limit 1" ]
   if as and as[0] and (c==nil or as[0].date<c.date) then
     c=Contact.new
     c.callsign1=as[0].callsign
     c.date=as[0].date
     c.time=as[0].date
     c.callsign2=""
     c.id=-99
     #find first chase
     if as[0].external_activation_id then acs=ExternalChase.find_by_sql [ "select * from external_chases where external_activation_id=#{as[0].external_activation_id} order by time asc limit 1" ] end
     if acs and acs.count>0 then
       ac=acs.first
       c.callsign2=ac.callsign
     end
   end
 end

 c 
end

############################################################
# DETAILS OF ACTIVATIONS, CHASES ETC FOR THIS ASSET
############################################################
def activation_count
  logs=self.logs
  count=0
  logs.each do |log|
    if log.contacts.count>0 then count+=1 end
  end
  count
end

def activators
  cals1=Contact.where("? = ANY(asset1_codes)", self.code);
  callsigns1=cals1.map{|cal| u=User.find_by_callsign_date(cal.callsign1, cal.date); if u then u.callsign end};
  cals2=Contact.where("? = ANY(asset2_codes)", self.code);
  callsigns2=cals2.map{|cal| u=User.find_by_callsign_date(cal.callsign2, cal.date); if u then u.callsign end};
  callsigns=callsigns1+callsigns2
  users=User.where(callsign: callsigns).order(:callsign)
end

def external_activators
  cals=ExternalActivation.where(summit_code: self.code);
  callsigns=cals.map{|cal| if cal then cal.callsign end};
  users=User.where(callsign: callsigns).order(:callsign)
end

def activators_including_external
  users=self.external_activators+self.activators
  users.uniq.sort_by {|u| u.callsign}
end

def chasers
  cals=Contact.where("? = ANY(asset1_codes)", self.code);
  callsigns1=cals.map{|cal| u=User.find_by_callsign_date(cal.callsign2, cal.date); if u then u.callsign else nil end};
  cals2=Contact.where("? = ANY(asset2_codes)", self.code);
  callsigns2=cals2.map{|cal| u=User.find_by_callsign_date(cal.callsign1, cal.date); if u then u.callsign else nil end};
  callsigns=callsigns1+callsigns2
  users=User.where(callsign: callsigns).order(:callsign)
end

def external_chasers
  cals=ExternalChase.where(summit_code: self.code);
  callsigns=cals.map{|cal| cal.callsign};
  users=User.where(callsign: callsigns).order(:callsign)
end

def chasers_including_external
  users=self.external_chasers+self.chasers
  users.uniq.sort_by {|u| u.callsign}
end



#############################################################
# Lookthrough to underlying asset type specific tables
# - Used as different asset types have different patrameters
# - AssetType.tablename defines table underlying each asset type
# - AssetType.fields lists fields to be displayed for each asset type
#############################################################

#Return underlying table containing info about this asset
def table
  self.type.table_name.safe_constantize
end

#Return underlying record containing info about this asset
def record
  self.type.table_name.safe_constantize.find_by(self.type.index_name => self.code)
end

#Return value of field <name> from the underlying table for this asset
def r_field(name)
  if self.record and self.record.respond_to? name then
    self.record[name]
  else
    nil
  end
end

#################################################################
# SIMPLE QUERIES
#################################################################
# return true if this asset activated by given callsign
def activated_by?(callsign)
  if callsign and callsign!="" and callsign!="*" then 
    callsign=callsign.upcase

    cs=Contact.find_by_sql [ ' select id from contacts where (callsign1 = ? and ? = ANY(asset1_codes)) or (callsign2 = ? and ? = ANY(asset2_codes)) limit 1 ', callsign, self.code, callsign, self.code ]

    as=ExternalActivation.find_by_sql [ "select * from external_activations where summit_code='"+self.code+"' and callsign = '"+callsign+"' limit 1" ]

    if (as and as.count>0) or (cs and cs.count>0) then true else false end
  else
    cs=Contact.find_by_sql [ ' select id from contacts where (? = ANY(asset1_codes)) or (? = ANY(asset2_codes)) limit 1 ', self.code, self.code ]

    as=ExternalActivation.find_by_sql [ "select * from external_activations where summit_code='"+self.code+"' limit 1" ]
    if (as and as.count>0) or (cs and cs.count>0) then true else false end
  end

end

# return true if this asset chased by given callsign
def chased_by?(callsign)
  if callsign and callsign!="" and callsign!="*" then
    callsign=callsign.upcase
    cs=Contact.find_by_sql [ ' select id from contacts where (callsign2 = ? and ? = ANY(asset1_codes)) or (callsign1 = ? and ? = ANY(asset2_codes)) limit 1 ', callsign, self.code, callsign, self.code ]

    as=ExternalChase.find_by_sql [ "select * from external_chases where summit_code='"+self.code+"' and callsign = '"+callsign+"' limit 1" ]

    if (as and as.count>0) or (cs and cs.count>0) then true else false end
  else
    cs=Contact.find_by_sql [ ' select id from contacts where (? = ANY(asset1_codes)) or (? = ANY(asset2_codes)) limit 1 ', self.code, self.code ]

    as=ExternalChase.find_by_sql [ "select * from external_chases where summit_code='"+self.code+"' limit 1" ]

    if (as and as.count>0) or (cs and cs.count>0) then true else false end
  end
end

#turn code into a URL-safe version
def get_safecode
  safecode=code.gsub("/","_")
end

#Turn URL-safe 'safecode' into a code
def self.decode_safecode(safecode)
  code=safecode.gsub("_","/")
end

########################################################
# Assets containing this asset
########################################################

#Asset list for all assets containing us
def contained_by_assets
  assets=Asset.find_by_sql [ " select a.* from asset_links al inner join assets a on a.code=al.containing_code where al.contained_code = '#{self.code}' and a.is_active=true " ]
end

#Asset names for all assets containing us
def contained_by_names
  assets=Asset.find_by_sql [ " select a.name, a.code, a.safecode from asset_links al inner join assets a on a.code=al.containing_code where al.contained_code = '#{self.code}' and a.is_active=true " ]
end

#Asset types for all assets containing us
def contained_by_classes 
  als=AssetLink.where(contained_code: self.code)
  acs=als.map{|al| al.child.asset_type}
  acs.uniq 
end

# return assets containing this asset that match specified type
def contained_by_by_type(asset_type)
  als=AssetLink.where(contained_code: self.code)
  codes=als.map{|al| al.containing_code}
  assets=Asset.where(:code => codes, :asset_type => asset_type, :is_active =>true)
end


########################################################
# Assets contained by this asset
########################################################

#Asset list (assets we contain)
def contains_assets
  assets=Asset.find_by_sql [ " select a.* from asset_links al inner join assets a on a.code=al.contained_code where al.containing_code = '#{self.code}' and a.is_active=true " ]
end

#Asset type list (assets we contain)
def contains_classes
  als=AssetLink.where(containing_code: self.code)
  acs=als.map{|al| al.parent.asset_type}
  acs.uniq 
end

######################################################
# GET INFO ABOUT ASSET FROM CODE
######################################################

# Provide infomation about the asset that a code refers to
# Checks:
# - Assets table
# - VkAssets table
# - then calculates info based on the code from fixed rules
#   for any other codes
# Input: codes: [code]
# Returns:
#   assets: [{
#           asset: Asset
#           name: Name of asset (or code if we do not know name)
#           url: URL of this asset as locally as possible (here=>PnP=>award programme)
#           external: true if not hosted on ontheair
#           code: code
#           type: AssetType
#           title: Award programme name
#         }]

def self.assets_from_code(codes)
  assets=[]
  if codes then 
    code_arr=codes.split(',') 
    code_arr.each do |code|
      code=code.gsub('[','').gsub(']','')
      code=code.lstrip
      asset={asset: nil, code: nil, name: nil, url: nil, external: nil, type: nil}
      if code then
        code=code.upcase
        a=Asset.find_by(code: code.split(' ')[0])
        if !a then
          a=Asset.find_by(old_code: code.split(' ')[0])
        end
        va=VkAsset.find_by(code: code.split(' ')[0])

        #Assets listed on ontheair.nz - look up in db
        if a then
          asset[:asset]=a
          asset[:url]=a.url
          if a[:url][0]=='/' then a[:url]=a[:url][1..-1] end
          asset[:name]=a.name
          asset[:codename]=a.codename
          asset[:external]=false
          asset[:code]=a.code
          asset[:type]=a.asset_type
          if !code.match(/ZL^[a-zA-Z]-./)  then
             asset[:external_url]=a.external_url
          end
          if a.type then asset[:title]=a.type.display_name else logger.error "ERROR: cannot find type "+a.asset_type end
          if asset[:url][0]!='/' then asset[:url]='/'+asset[:url] end

        #Assets in VK pulled in from PnP - look up in VK db tables
        elsif va then
          asset[:asset]=va
          asset[:url]='/vkassets/'+va.get_safecode
          asset[:name]=va.name
          asset[:codename]=va.codename
          asset[:external]=false
          asset[:code]=va.code
          asset[:type]=va.award
          if asset[:type]=='SOTA' then asset[:type]='summit' end
          if asset[:type]=='POTA' then asset[:type]='pota park' end
          if asset[:type]=='WWFF' then asset[:type]='wwff park' end
          asset[:external_url]=va.external_url

          asset[:title]=va.site_type

        #Otherwise - we guess based on the reference
        elsif thecode=code.match(HEMA_REGEX) then
          #HEMA
          logger.debug "HEMA"
          asset[:name]=code
          asset[:url]='http://hema.org.uk'
          asset[:external]=true
          asset[:code]=thecode.to_s
          asset[:type]='hump'
          asset[:title]="HEMA"

        elsif thecode=code.match(SIOTA_REGEX)  then
          #SiOTA
          logger.debug "SiOTA"
          asset[:name]=code
          asset[:url]=SIOTA_ASSET_URL+thecode.to_s
          asset[:external]=true
          asset[:code]=thecode.to_s
          asset[:type]='silo'
          asset[:title]="SiOTA"

        elsif thecode=code.match(POTA_REGEX)  then
          #POTA
          logger.debug "POTA"
          asset[:url]=POTA_ASSET_URL+thecode.to_s
          asset[:title]="POTA"
          asset[:name]=code
          asset[:external]=true
          asset[:code]=thecode.to_s
          asset[:type]='pota park'

        elsif thecode=code.match(WWFF_REGEX) then
          #WWFF
          logger.debug "WWFF"
          logger.debug thecode
          asset[:url]=WWFF_ASSET_URL+thecode.to_s
          asset[:name]=code
          asset[:external]=true
          asset[:code]=thecode.to_s
          asset[:type]='wwff park'
          asset[:title]="WWFF"

        elsif thecode=code.match(SOTA_REGEX) then
          #SOTA
          logger.debug "SOTA"
          asset[:name]=code
          asset[:url]=SOTA_ASSET_URL+thecode.to_s
          asset[:external]=true
          asset[:code]=thecode.to_s
          asset[:type]='summit'
          asset[:title]="SOTA"
        end
        if asset[:code] then
          assets.push(asset)
        end
      end  #if code provided
    end #for each code in codes
  end #if codes provided

  assets
end

#Asset type
def self.get_asset_type_from_code(code)
  a=Asset.assets_from_code(code)
  if a and a.first and a.first[:type] then a.first[:type] else 'all' end
end

# Provide an external URL for this internal asset, if we know of one
# Should be the link to the asset page for this asset on the website
# of the governing award programme
# Returns: url: Url
def external_url
  url=nil
  code=self.code.lstrip
  asset_type=self.asset_type
  if asset_type=="pota park" then
    #POTA
    url=POTA_ASSET_URL+code
  elsif asset_type=='wwff park' then
    #WWFF
    url=WWFF_ASSET_URL+code
  elsif asset_type=='summit' then
    #SOTA
    url=SOTA_ASSET_URL+code
  elsif asset_type=='hump' and self.old_code and self.old_code.to_i>0 then
    #HEMA
    url=HEMA_ASSET_URL+self.old_code 
  end
  url
end

# Return the activity class used by PnP for a given asset code / reference
# Uses Asset table for known assets
# Looks up the reference against naming rules if not in our database
def self.get_pnp_class_from_code(code)
  aa=Asset.assets_from_code(code)
  pnp_class="QRP" 
  if aa then
    a=aa.first 
    if a then 
      if a and a[:type] and a[:external]==false then 
         ac=AssetType.find_by(name: a[:type])
         pnp_class=ac.pnp_class
      elsif a[:title][0..3]=="WWFF" then pnp_class="WWFF"
      elsif a[:title][0..3]=="POTA" then pnp_class="POTA"
      elsif a[:title][0..3]=="HEMA" then pnp_class="HEMA"
      elsif a[:title][0..4]=="SiOTA" then pnp_class="SiOTA"
      end
    end
  end
  pnp_class
end


##################################################################
# HELPERS
#
# Providing common services for assets to other models
#
##################################################################

# Replaces codes with master_code if one exists
# for a repaced asset
# Input: [codes]
# Returns: [codes]
def self.find_master_codes(codes)
  newcodes=[]
  codes.each do |code|
  a=Asset.find_by(code: code)

    if a and a.is_active==false
      if a.master_code then
        code=a.master_code
      end
    end
    newcodes+=[code]
  end
  newcodes.uniq
end

#Extract asset coodes from a textual description field
#Input: string
#Returns: [codes]
def self.check_codes_in_text(location_text)
      assets=Asset.assets_from_code(location_text)
      asset_codes=[]
      assets.each do |asset|
        if asset and asset[:code] then
          if asset_codes==[] then
            asset_codes=["#{asset[:code].to_s}"]
          else
            asset_codes.push("#{asset[:code]}")
          end
        end
      end
   asset_codes
end

#Find most accurate location (lat/long) from a list of codes
#if loc_source is provided then act as if we already have a location of 
#that type (area||point||user) and only find things more accurate
#Input: [codes], 'area' or 'point' or nil
#Returns: {location: Point, loc_source: 'point'||'area'||'user', asset: Asset
def self.get_most_accurate_location(codes, loc_source="", location=nil)
  loc_asset=nil
  accuracy=999999999999

  if codes.count>1 then
    codes.each do |code|
      logger.debug "DEBUG: assessing code2 #{code}"
      assets=Asset.find_by_sql [ " select id, asset_type, location, area from assets where code='#{code}' limit 1" ]
      if assets then asset=assets.first else asset=nil end
      if asset then
        #only consider polygon loc's if we don't already have a point loc
        #use this location if polygon area smaller than previous polygon used
        if asset.type.has_boundary then
          if loc_source!="point" and loc_source!="user" and asset.area and asset.area<accuracy then
            location=asset.location
            loc_asset=asset
            accuracy=asset.area
            loc_source='area'
            logger.debug "DEBUG: Assigning polygon locn"
          end
        else
          if loc_source!="user" then
            #if there are two point locations (e.g. summit and hut)
            #just use the last found (no way to know which is more accurate)
            if loc_source=='point' then
                logger.debug "Multiple POINT locations found"
            end

            #assign point location
            location=asset.location
            loc_asset=asset
            loc_source='point'
            logger.debug "DEBUG: Assigning point locn"
          end
        end
      end
    end
  end
  #single asset or nothing found from search, just use the first location
  if !location and codes.count>0 then
    assets=Asset.find_by_sql [ " select id, asset_type, location, area from assets where code='#{codes.first}' limit 1" ]
    if assets and assets.count>0 then 
      loc_asset=assets.first 
      if loc_asset.type.has_boundary then loc_source='area' else loc_source='point' end
      location=loc_asset.location
    end
  end
  {location: location, source: loc_source, asset: loc_asset}
end


#Catch common errors in separators used in references in ZLOTA formats:
# ZLx/xx-###
# ZLx/####
def self.correct_separators(code)
  #ZLOTA
  if code.match(/^[zZ][lL][a-zA-Z][-_\/][a-zA-Z]{2}[-_\/]\d{3,4}/) then
     code[3]='/'
     code[6]='-'
  elsif code.match(/^[Zz][Ll][a-zA-Z][-_\/]\d{3,4}/) then
     code[3]='/'
  end
  code 
end

#Calculate maindenhead for any location (point)
#Input location: Point
#Returns: maidenhead: string
def self.get_maidenhead_from_location(location)
  a=Asset.new
  a.location=location
  a.maidenhead
end

#Look up all assets that contain a given location point / polygon
#Optionally provide an asset from which the location was derived
#Input: location: Point, asset: Asset or nil
#Returns: codes: [code]
#
#TODO: Logic here is same as that in def add_links, can the two be combined?
def self.containing_codes_from_location(location, asset=nil)
  loc_type="point" 
  codes=[]
  if asset and asset.type.has_boundary and asset.area and asset.area>0 then 
    loc_type="area"
  end

  if !location.nil? and location.to_s.length>0 then
    #find all assets containing this location point
    codes=Asset.find_by_sql [ "select code from assets a inner join asset_types at on at.name=a.asset_type where a.is_active=true and at.has_boundary=true and ST_Within(ST_GeomFromText('#{location}',4326), a.boundary); " ];
    # For locations based on a polygon:
    # filter the list by those that overlap at least 90% of the asset
    # defining our polygon
    if loc_type=="area" then
      logger.debug "Filtering codes by area overlap"
      validcodes=[]
      codes.each do |code|
        overlap=ActiveRecord::Base.connection.execute( " select ST_Area(ST_intersection(a.boundary, b.boundary)) as overlap, ST_Area(a.boundary) as area from assets a join assets b on b.code='#{code.code}' where a.id=#{asset.id}; ")
        prop_overlap=overlap.first["overlap"].to_f/overlap.first["area"].to_f
        logger.debug "DEBUG: overlap #{prop_overlap.to_s} "+code.code
        if prop_overlap>0.9 then
          validcodes+=[code]
        end
      end
      codes=validcodes
    end
  end
  codelist=codes.map{|c| c.code}
end

# Look up all assets that are contained by a given asset (by code)
# Input: code: string
# Returns: codes: [code]
def self.containing_codes_from_parent(code)
  code=code.upcase
  codes=AssetLink.find_by_sql [ "select containing_code from asset_links al inner join assets a on al.containing_code = a.code where contained_code='#{code}' and is_active=true;" ]
  codelist=codes.map{|c| c.containing_code}
end

# Find the next free unused code for an asset type
# (in a region, if asset tyoes uses regions)
# Input: asset_type: AssetType.name, region: region.name
# Returns: code: string
def self.get_next_code(asset_type, region='ZZ')
  if !region then region="ZZ" end
  logger.debug  "Region :"+region
  newcode=nil
  use_region=true
  length=4
  if asset_type=='hut' then prefix='ZLH/'; length=3 end
  if asset_type=='park' then prefix='ZLP/'; length=4 end
  if asset_type=='island' then prefix='ZLI/'; length=3 end
  if asset_type=='lake' then prefix='ZLL/'; length=4; use_region=false end
  if asset_type=='lighthouse' then prefix='ZLB/';length=3; use_region=false end

  if prefix then 
    #ZLx/XX-### or ZLx/XX-#### format codes
    if use_region and region and region!="" then
      #get last asset of this type for this region
      last_asset=Asset.where("code like '"+prefix+region+"-%%'").order(:code).last
      #try and determine number length from last asset code
      if last_asset then
        logger.debug last_asset
        codestring=last_asset.code[7..-1]
      #or default to 0000
      else 
        codestring="0"*length
      end

      # add one to last asset code
      codenumber=codestring.to_i
      codenumber+=1
      newcode=prefix+region+'-'+(codenumber.to_s.rjust(codestring.length,'0'))

    #ZLx/#### format codes
    else
      #get last asset of this type
      last_asset=Asset.where(:asset_type => asset_type).order(:code).last
      #try and determine number length from last asset code
      if last_asset then
       codestring=last_asset.code[4..-1]
      #or default to 000
      else 
        codestring="0"*length 
      end
      # add one to last asset code
      codenumber=codestring.to_i
      codenumber+=1
      newcode=prefix+(codenumber.to_s.rjust(codestring.length,'0'))
    end
  end
  logger.debug "Code: "+newcode
  newcode
end


#################################################################
# Imprting assets from externally sourced tables
# Generally doen in 2 steps:
# - read from external provider into a custom table which
#   we can safely trash if things go wrong
# - read from that table into the master assets table
################################################################

#See lib/asset_import_tools.rb
# def self.add_parks
# def self.add_huts
# def self.add_islands
# def self.add_lakes
# def self.add_lake(l)
# def self.add_sota_peak(p)
# def self.add_pota_parks
# def self.add_pota_park(p, existing_asset)
# def self.add_humps
# def self.add_hump(p, existing_asset)
# def self.add_lighthouses
# def self.add_lighthouse(p, existing_asset)
# def self.add_wwff_parks
# def self.add_wwff_park(p, existing_asset)



###################################################################
# GIS DATA HANDLING
###################################################################
# see lib/asset_gis_tools for:
# per-asset methods:
#   def calc_location
#   def add_sota_activation_zone
#   def add_simple_boundary
#   def add_area
#   def add_altitude
#   def add_buffered_activation_zone
#   def get_access
#   def get_access_with_buffer(buffer)
# Asset. methods:
#   def self.add_areas
#   def self.fix_invalid_polygons
#   def self.add_simple_boundaries



############################################################
# UTILS TO CALL FROM CONSOLE
# See lib/asset_console_tools.rb
#
# def self.add_regions
# def self.add_districts
# def self.add_links
# def self.prune_links
# def self.update_all
# def self.add_centroids
# def self.add_sota_activation_zones(force=false)
# def self.add_hema_activation_zones(force=false)
# def self.get_hema_access
# def self.get_sota_access
# def self.get_lake_access


def self.get_custom_connection(identifier, dbname, dbuser, password)
  eval("Custom_#{identifier} = Class::new(ActiveRecord::Base)")
  eval("Custom_#{identifier}.establish_connection(:adapter=>'postgis', :database=>'#{dbname}', " +
      ":username=>'#{dbuser}', :password=>'#{password}')")
  return eval("Custom_#{identifier}.connection")
end

end
