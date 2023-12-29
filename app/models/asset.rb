class Asset < ActiveRecord::Base

# after_save :post_process
 validates :code, presence: true, uniqueness: true
 validates :name, presence: true
 before_validation { self.assign_calculated_fields }
 after_save {self.add_links}

def assign_calculated_fields
  if !self.valid_from then self.valid_from=Time.new('1900-01-01') end
  if self.minor!=true then self.minor=false end

  if self.code==nil or self.code=="" then
    self.code=Asset.get_next_code(self.asset_type,self.region)
  end
  if self.safecode==nil or self.safecode=="" then
    self.safecode=self.code.gsub('/','_')
  end

  if self.district==nil or self.district=="" then
    self.district=self.add_district()
  end
  self.url='assets/'+self.safecode
  #add links
#  self.add_links
end

def name_and_location
  text=self.name+" ["+self.code+"]"
  if location then text=text+" {"+self.maidenhead+"}" end
  text
end

def self.get_maidenhead_from_location(location)
  a=Asset.new
  a.location=location
  a.maidenhead
end

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

def boundary_simple
   pp=Asset.find_by_sql [ "select id, ST_NPoints(boundary) as altitude from assets where id="+self.id.to_s ]
   if pp then 
     lenfactor=Math.sqrt((pp.first.altitude||0)/10000)
     rnd=0.000002*10**lenfactor
     boundarys=Asset.find_by_sql [ 'select id, ST_AsText(ST_Simplify("boundary", '+rnd.to_s+')) as "boundary" from assets where id='+self.id.to_s ]  
     boundary=boundarys.first.boundary
     boundary
   else nil end
end

def district_name
  name=""
  r=District.find_by(district_code: self.district)
  if r then r.name else "" end
end

def region_name
  name=""
  r=Region.find_by(sota_code: self.region)
  if r then name=r.name.gsub('Region','') end
end

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

def self.get_next_code(asset_type, region)
  if !region then region="ZZ" end
  puts "Region :"+region
  newcode=nil
  use_region=true
  if asset_type=='hut' then prefix='ZLH/' end
  if asset_type=='park' then prefix='ZLP/' end
  if asset_type=='island' then prefix='ZLI/' end
  if asset_type=='lake' then prefix='ZLL/'; use_region=false end

  if prefix then 
    if use_region and region and region!="" then
      last_asset=Asset.where("code like '"+prefix+region+"-%%'").order(:code).last
      puts last_asset
      codestring=last_asset.code[7..-1]
       codenumber=codestring.to_i
       codenumber+=1
       newcode=prefix+region+'-'+(codenumber.to_s.rjust(codestring.length,'0'))
    else
      last_asset=Asset.where(:asset_type => asset_type).order(:code).last
      codestring=last_asset.code[3..-1]
       codenumber=codestring.to_i
       codenumber+=1
       newcode=prefix+(codenumber.to_s.rjust(codestring.length,'0'))
    end

  end
  puts "Code: "+newcode
  newcode
end

def activated_by?(callsign)
  if callsign and callsign!="" and callsign!="*" then 
    callsign=callsign.upcase

    cs=Contact.find_by_sql [ ' select id from contacts where (callsign1 = ? and ? = ANY(asset1_codes)) or (callsign2 = ? and ? = ANY(asset2_codes)) limit 1 ', callsign, self.code, callsign, self.code ]

    as=SotaActivation.find_by_sql [ "select * from sota_activations where summit_code='"+self.code+"' and callsign = '"+callsign+"' limit 1" ]

    if (as and as.count>0) or (cs and cs.count>0) then true else false end
  else
    cs=Contact.find_by_sql [ ' select id from contacts where (? = ANY(asset1_codes)) or (? = ANY(asset2_codes)) limit 1 ', self.code, self.code ]

    as=SotaActivation.find_by_sql [ "select * from sota_activations where summit_code='"+self.code+"' limit 1" ]
    if (as and as.count>0) or (cs and cs.count>0) then true else false end
  end

end

def chased_by?(callsign)
  if callsign and callsign!="" and callsign!="*" then
    callsign=callsign.upcase
    cs=Contact.find_by_sql [ ' select id from contacts where (callsign2 = ? and ? = ANY(asset1_codes)) or (callsign1 = ? and ? = ANY(asset2_codes)) limit 1 ', callsign, self.code, callsign, self.code ]

    as=SotaChase.find_by_sql [ "select * from sota_chases where summit_code='"+self.code+"' and callsign = '"+callsign+"' limit 1" ]

    if (as and as.count>0) or (cs and cs.count>0) then true else false end
  else
    cs=Contact.find_by_sql [ ' select id from contacts where (? = ANY(asset1_codes)) or (? = ANY(asset2_codes)) limit 1 ', self.code, self.code ]

    as=SotaChase.find_by_sql [ "select * from sota_chases where summit_code='"+self.code+"' limit 1" ]

    if (as and as.count>0) or (cs and cs.count>0) then true else false end
  end
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
   as=SotaActivation.find_by_sql [ "select * from sota_activations where summit_code='"+self.code+"' order by date asc limit 1" ]
   puts as[0]
   if as and as[0] and (c==nil or as[0].date<c.date) then
     c=Contact.new
     c.callsign1=as[0].callsign
     c.date=as[0].date
     c.time=as[0].date
     c.callsign2=""
     c.id=-99
     #find first chase
     acs=SotaChase.find_by_sql [ "select * from sota_chases where sota_activation_id=#{as[0].sota_activation_id} order by time asc limit 1" ]
     if acs and acs.count>0 then
       ac=acs.first
       c.callsign2=ac.callsign
     end
   end
 end

 c 
end

def r_field(name)
  if self.record and self.record.respond_to? name then
    self.record[name]
  else
    nil
  end
end

def web_links
  awl=AssetWebLink.where(asset_code: self.code)
end
def hutbagger_link
  awl=AssetWebLink.find_by(asset_code: self.code, link_class: 'hutbagger')
end

def codename
 "["+self.code+"] "+self.name
end
def type
  type=AssetType.find_by(name: self.asset_type)
  if !type then  type=AssetType.find_by(name: 'all') end
  type
end

def get_safecode
  safecode=code.gsub("/","_")
end

def table
  self.type.table_name.safe_constantize
end

def record
  self.type.table_name.safe_constantize.find_by(self.type.index_name => self.code)
end

def children
  assets=Asset.find_by_sql [ " select a.* from asset_links al inner join assets a on a.code=al.child_code where al.parent_code = '#{self.code}' " ]
#  als=AssetLink.where(parent_code: self.code)
#  codes=als.map{|al| al.child_code}
#  assets=Asset.where(:code => codes, is_active: true)
end

def childnames
  assets=Asset.find_by_sql [ " select a.name, a.code, a.safecode from asset_links al inner join assets a on a.code=al.child_code where al.parent_code = '#{self.code}' " ]
end

def child_classes
  als=AssetLink.where(parent_code: self.code)
  acs=als.map{|al| al.child.asset_type}
  acs.uniq 
end

def parent_classes
  als=AssetLink.where(child_code: self.code)
  acs=als.map{|al| al.parent.asset_type}
  acs.uniq 
end

def parents
  als=AssetLink.where(child_code: self.code)
  codes=als.map{|al| al.parent_code}
  assets=Asset.where(:code => codes, is_active: true)
end

def linked_assets
  als=AssetLink.find_by_parent(self.code)
  codes=als.map{|al| al.child_code}
  assets=Asset.where(:code => codes)
end

def linked_assets_by_type(asset_type)
  als=AssetLink.find_by_parent(self.code)
  codes=als.map{|al| al.child_code}
  assets=Asset.where(:code => codes, :asset_type => asset_type)
end

def get_external_url
    url=nil
    code=self.code.lstrip
    if code.match(/^[a-zA-Z0-9]{1,2}-\d{4,5}/)  then
        #POTA
        if code[0..1].upcase=='VK' then
          url='https://parksnpeaks.org/getPark.php?actPark='+code+'&submit=Process'
        else
          url='http://pota.app/#/park/'+code
        end  
      elsif code.match(/^[a-zA-Z]{1,2}[fF]{2}-\d{4}/) then
        #WWFF
        if code[0..1].upcase=='VK' then
          url='https://parksnpeaks.org/getPark.php?actPark='+code+'&submit=Process'
        else
          url='http://wwff.co/directory/?showRef='+code
        end
      elsif code.match(/^[a-zA-Z]{1,2}\d{0,1}\/[a-zA-Z]{2}-\d{3}/) then
        #SOTA
        url="https://summits.sota.org.uk/summit/"+code
      end
  url

end

def self.filter_codes(codes, asset_type)
   filtered_codes=[]
   codes.each do |code|
      aa=Asset.assets_from_code(code)
      a=aa.first
      if a[:type]==asset_type then
        filtered_codes.push(a[:asset].code)
      end
   end 
   filtered_codes
end

def self.get_pnp_class_from_code(code)
  aa=Asset.assets_from_code(code)
  a=aa.first 
  pnp_class="QRP" 
  if a and a[:type] and a[:external]==false then 
     ac=AssetType.find_by(name: a[:type])
     pnp_class=ac.pnp_class
  elsif a[:title][0..3]=="WWFF" then pnp_class="WWFF"
  elsif a[:title][0..3]=="POTA" then pnp_class="POTA"
  elsif a[:title][0..3]=="HEMA" then pnp_class="HEMA"
  elsif a[:title][0..4]=="SiOTA" then pnp_class="SiOTA"
  end

  pnp_class
end

def self.get_code_from_codename(codename)
  if codename then code=codename.split(']')[0] else code='' end
  code=code.gsub('[','').gsub(']','')
end

def self.get_asset_type_from_code(code)
  a=Asset.assets_from_code(code)
  if a and a.first and a.first[:type] then a.first[:type] else 'all' end
end

def self.add_parks
  ps=Park.find_by_sql [ 'select id from parks;' ]
  ps.each do |pid|
    p=Park.find_by_id(pid)
    a=Asset.find_by(asset_type: 'park', code: p.dist_code)
    if !a then  a=Asset.find_by(asset_type: 'park', code: p.code) end
    if !a then a=Asset.new;new=true;puts "New" else new=false end
    a.asset_type="park"
    a.code=p.dist_code
    a.old_code=p.code
    if p.master_id then
       cp=Crownpark.find_by_id(p.master_id)
       if cp then pp=Park.find_by_id(cp.napalis_id)  else pp=nil end
       if pp then a.master_code=pp.dist_code 
       else puts "ERROR: failed to find park "+p.master_id.to_s+" master for "+p.dist_code+" "+p.name; p.master_id=nil; a.master_code=nil; end
    end
    a.safecode=a.code.gsub('/','_')
    a.url='assets/'+a.safecode
    a.name=p.name.gsub("'","''")
    a.description=(p.description||"").gsub("'","''")
    a.is_active=p.is_active and not p.is_mr
    a.category=(p.owner||"").gsub("'","''")
    a.location=p.location
    if new then a.save end
    ActiveRecord::Base.connection.execute("update assets set code='"+a.code+"', old_code='"+(a.old_code||"")+"',master_code='"+(a.master_code||"")+"', safecode='"+a.safecode+"', url='"+a.url+"', name='"+a.name+"', description='"+(a.description||"")+"', is_active="+a.is_active.to_s+", category='"+(a.category||"")+"', location=(select location from parks where id="+p.id.to_s+"),  boundary=(select boundary from parks where id="+p.id.to_s+") where id="+a.id.to_s+";")

    puts a.code
  end 
  true
end

def self.child_codes_from_parent(code)
  code=code.upcase
  codes=AssetLink.find_by_sql [ "select child_code from asset_links al inner join assets a on al.child_code = a.code where parent_code='#{code}' and is_active=true;" ]
  codelist=codes.map{|c| c.child_code}
end

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
	      va=VkAsset.find_by(code: code.split(' ')[0])
	      if a then
		  asset[:asset]=a
		  asset[:url]=a.url
		  if a[:url][0]=='/' then a[:url]=a[:url][1..-1] end
		  asset[:name]=a.name
		  asset[:external]=false
		  asset[:code]=a.code
		  asset[:type]=a.asset_type
		  if !code.match(/ZL^[a-zA-Z]-./)  then
		     asset[:external_url]=a.get_external_url
		  end

		  if a.type then asset[:title]=a.type.display_name else puts "ERROR: cannot find type "+a.asset_type end
		  if asset[:url][0]!='/' then asset[:url]='/'+asset[:url] end
	      elsif va then
		  asset[:asset]=va
		  asset[:url]='/vkassets/'+va.get_safecode
		  asset[:name]=va.name
		  asset[:external]=false
		  asset[:code]=va.code
		  asset[:type]=va.award
		  if asset[:type]=='SOTA' then asset[:type]='summit' end
		  if asset[:type]=='POTA' then asset[:type]='pota park' end
		  if asset[:type]=='WWFF' then asset[:type]='wwff park' end
		  asset[:external_url]=va.get_external_url

		  asset[:title]=va.site_type
	      elsif thecode=code.match(/^[a-zA-Z]{1,2}\d\/H[a-zA-Z]{2}-\d{3}/) then
		#HEMA
		 puts "HEMA"
		  asset[:name]=code
		  asset[:url]='https://parksnpeaks.org/showAward.php?award=HEMA'
		  asset[:external]=true
		  asset[:code]=thecode.to_s
		  asset[:type]='hump'
		  asset[:title]="HEMA"
	      elsif thecode=code.match(/^VK-[a-zA-Z]{3}\d{1}/)  then
		#SiOTA
		 puts "SiOTA"
		  asset[:name]=code
		  asset[:url]='https://www.silosontheair.com/silos/#'+thecode.to_s
		  asset[:external]=true
		  asset[:code]=thecode.to_s
		  asset[:type]='silo'
		  asset[:title]="SiOTA"
	      elsif thecode=code.match(/^[a-zA-Z0-9]{1,2}-\d{4,5}/)  then
		#POTA
		puts "POTA"
		if code[0..1].upcase=='VK' then
		  asset[:name]=code
		  asset[:url]='https://parksnpeaks.org/getPark.php?actPark='+thecode.to_s+'&submit=Process'
		  asset[:external]=true
		  asset[:code]=thecode.to_s
		  asset[:type]='pota park'
		  asset[:title]="POTA - VK"
		else
		  asset[:name]=code
		  asset[:url]='https://pota.app/#/park/'+thecode.to_s
		  asset[:external]=true
		  asset[:code]=thecode.to_s
		  asset[:type]='pota park'
		  asset[:title]="POTA"
		end  
	      elsif thecode=code.match(/^[a-zA-Z]{1,2}[fF]{2}-\d{4}/) then
		#WWFF
		 puts "WWFF"
		puts thecode
		if code[0..1].upcase=='VK' then
		  asset[:name]=code
		  asset[:url]='https://parksnpeaks.org/getPark.php?actPark='+thecode.to_s+'&submit=Process'
		  asset[:external]=true
		  asset[:code]=thecode.to_s
		  asset[:type]='wwff park'
		    asset[:title]="WWFF - VK"
		else
		  asset[:name]=code
		  asset[:url]='https://wwff.co/directory/?showRef='+thecode.to_s
		  asset[:external]=true
		  asset[:code]=thecode.to_s
		  asset[:type]='wwff park'
		  asset[:title]="WWFF"
		end
	      elsif thecode=code.match(/^[a-zA-Z]{1,2}\d{0,1}\/[a-zA-Z]{2}-\d{3}/) then
		#SOTA
		 puts "SOTA"
		asset[:name]=code
		asset[:url]="https://summits.sota.org.uk/summit/"+thecode.to_s
		asset[:external]=true
		asset[:code]=thecode.to_s
		asset[:type]='summit'
		asset[:title]="SOTA"
	      elsif thecode=code.match(/[a-zA-Z]{1,2}\d\/H[a-zA-Z]{2}-\d{3}/) then
		 puts "HEMA"
		#HEMA
		asset[:name]=code
		asset[:url]='https://parksnpeaks.org/showAward.php?award=HEMA'
		asset[:external]=true
		asset[:code]=thecode.to_s
		asset[:type]='summit'
		asset[:title]="HEMA"
	      end
	      if asset[:code] then
		assets.push(asset)
	      end
	   end 
	  end 
	  end
	  assets

	end



	def self.add_huts
	  ps=Hut.all
	  ps.each do |p|
	    a=Asset.find_by(asset_type: 'hut', code: p.code)
	    if !a then a=Asset.new end
	    a.asset_type="hut"
	    a.code=p.code
	    a.url='/huts/'+p.id.to_s
	    a.name=p.name
	    a.description=p.description
	    a.is_active=p.is_active
	    a.location=p.location
	    a.altitude=p.altitude
	    a.save
	    puts a.code
	  end
	  true
	end
	def self.add_islands
	  ps=Island.all
	  ps.each do |p|
	    a=Asset.find_by(asset_type: 'island', code: p.code)
	    if !a then a=Asset.new end
	    a.asset_type="island"
	    a.code=p.code_dist
	    a.old_code=p.code
	    a.url='asset/'+a.code
	    a.name=p.name
	    a.description=p.info_description
	    a.is_active=p.is_active
	    a.location=p.WKT
	    a.boundary=p.boundary
	    a.save
	    puts a.code
	  end
	  true
	end

	def self.add_lakes
	 ls=Lake.where(is_active: true)
	 ls.each do |l|
	    Asset.add_lake(l)
	 end
	end

	def self.add_lake(l)
	    a=Asset.find_by(asset_type: 'lake', code: l.code)
	    if !a then a=Asset.new; puts "New" end
	    a.asset_type="lake"
	    a.code=l.code
	    a.safecode=a.code.gsub('/','_')
	    a.url='/assets/'+a.safecode
	    a.is_active=true
	    a.name=l.name
	    a.location=l.location
	   a.boundary=l.boundary
	    a.ref_id=l.topo50_fid
	    a.save
	    puts a.code
	    a
	end

	def self.add_sota_peaks
	  ps=SotaPeak.all
	  ps.each do |p|
	    Asset.add_sota_peak(p)
	  end
	end
	def self.add_sota_peak(p)
	    a=Asset.find_by(asset_type: 'summit', code: p.summit_code)
	    if !a then a=Asset.new end
	    a.asset_type="summit"
	    a.code=p.summit_code
	    a.safecode=a.code.gsub('/','_')
	    a.url='/summits/'+p.short_code
	    a.is_active=true
	    a.name=p.name
	    a.location=p.location
	    a.points=p.points
	    a.altitude=p.alt
	    a.save
	    puts a.code
	    a
	end

	def self.add_pota_parks
	  ps=PotaPark.all
	  ps.each do |p|
	    Asset.add_pota_park(p)
	  end
	end

	def self.add_pota_park(p, existing_asset)
	    a=Asset.find_by(asset_type: 'pota park', code: p.reference)
	    if !a then a=Asset.new end
	    a.asset_type="pota park"
	    a.code=p.reference
	    a.safecode=p.reference.gsub('/','_')
	    a.is_active=true
	    if a.id and (a.name!=p.name or a.location!=p.location) then
	      puts "Exiting asset needs updating"
	      name=p.name.gsub("'","''")
	      if existing_asset  then
		ActiveRecord::Base.connection.execute("update assets set code='"+p.reference+"', name='"+name+"', is_active=true, location=ST_GeomFromText('POINT(#{p.location.x} #{p.location.y})',4326), boundary=(select boundary from assets where id="+existing_asset.id.to_s+") where id="+a.id.to_s+";")
	      else
		ActiveRecord::Base.connection.execute("update assets set code='"+p.reference+"', name='"+name+"', is_active=true, location=ST_GeomFromText('POINT(#{p.location.x} #{p.location.y})',4326) where id="+a.id.to_s+";")
	      end
	    elsif !a.id then
	      puts "Adding data to new asset"
	      a.name=p.name
	      a.location=p.location
	      a.save
	      if existing_asset  then
		ActiveRecord::Base.connection.execute("update assets set boundary=(select boundary from assets where id="+existing_asset.id.to_s+") where id="+a.id.to_s+";")
		a.add_simple_boundary
	      end
	    end

	    puts a.code
	    a
	end

	def self.add_lighthouses
	  ps=Lighthouse.where('code is not null')
	  ps.each do |p|
	    Asset.add_lighthouse(p, nil)
	  end
	end

	def self.add_wwff_parks
	  ps=WwffPark.all
	  ps.each do |p|
	    Asset.add_wwff_park(p, nil)
	  end
	end

	def self.add_lighthouse(p, existing_asset)
	    a=Asset.find_by(asset_type: 'lighthouse', code: p.code)
	    if !a then
	       a=Asset.new
	       puts "Adding new lighthouse"
	    end
	    a.asset_type="lighthouse"
	    if a.description=nil or a.description=="" then a.description=(p.loc_type||"").capitalize+" based "+(if p.str_type=="lighthouse" then "lighthouse" else "light/beacon" end)+(if p.status then " ("+p.status+")" else "" end) end
	    a.code=p.code
	    a.is_active=true
	    a.name=p.name
	    a.location=p.location 
	    a.region=p.region
	    if p.mnz_id != nil and p.mnz_id!="" then a.category="Maritime NZ" end
	    if a.name and a.name.length>0 then a.is_active=true else a.is_active=false end
	    a.save 
	    puts a.code
	    puts a.name
	    a
	end


	def self.add_wwff_park(p, existing_asset)
	    a=Asset.find_by(asset_type: 'wwff park', code: p.code)
	    if !a then a=Asset.new end
	    a.asset_type="wwff park"
	    a.code=p.code
	    a.is_active=true
	    
	    if a.id and (a.name!=p.name or a.location!=p.location) then
	      puts "Exiting asset needs updating"
	      name=p.name.gsub("'","''")
	      if existing_asset  then
		ActiveRecord::Base.connection.execute("update assets set code='"+p.code+"', name='"+name+"', is_active=true, location=ST_GeomFromText('POINT(#{p.location.x} #{p.location.y})',4326), boundary=(select boundary from assets where id="+existing_asset.id.to_s+") where id="+a.id.to_s+";")
	      else
		ActiveRecord::Base.connection.execute("update assets set code='"+p.code+"', name='"+name+"', is_active=true, location=ST_GeomFromText('POINT(#{p.location.x} #{p.location.y})',4326) where id="+a.id.to_s+";")
	      end
	    elsif !a.id then
	      puts "Adding data to new asset"
	      a.name=p.name
	      a.location=p.location
	      a.save 
	      if existing_asset  then
		ActiveRecord::Base.connection.execute("update assets set boundary=(select boundary from assets where id="+existing_asset.id.to_s+") where id="+a.id.to_s+";")
		a.add_simple_boundary 
	      end
	    end
	    puts a.code
	    a
	end


	def self.add_regions
	     count=0
	     a=Asset.first_by_id
	     while a do
	       puts a.code+" "+count.to_s
	       count+=1
	       a.add_region
	       a=Asset.next(a.id)
	     end
	end

	def self.add_districts
	     count=0
	     a=Asset.first_by_id
	     while a do
	       puts a.code+" "+count.to_s
	       count+=1
	       a.add_district
	       a=Asset.next(a.id)
	     end
	end

	def self.add_links
	  as=Asset.find_by_sql [ " select id,code from assets " ]
	  as.each do |aa|
	    puts aa.code
	    a=Asset.find_by_id(aa.id)
	    a.add_links
	  end
	end

	def self.prune_links
	  als=AssetLink.all
	  als.each do |al|
	    if !al.parent or !al.child then al.destroy end
	  end

	end

	def boundary_size
	  a=Asset.find_by_sql [ " select ST_NPoints(boundary) as id from assets where id = "+self.id.to_s ]
	  if a then a.first.id else 0 end
	end

	def contacts
	  contacts=Contact.find_by_sql [ "select * from contacts c where '"+self.code+"' = ANY(asset1_codes) or '"+self.code+"' = ANY(asset2_codes);" ]
	end

	def logs
	  logs=Log.find_by_sql [ "select * from logs l where '"+self.code+"' = ANY(asset_codes);" ]
	end

	def activators
	  cals=Contact.where("? = ANY(asset1_codes)", self.code);
	  callsigns=cals.map{|cal| User.find_by_callsign_date(cal.callsign1, cal.date).callsign};
	  users=User.where(callsign: callsigns).order(:callsign)
	end

	def activations
	  logs=self.logs
	  count=0
	  logs.each do |log|
	     if log.contacts.count>0 then count+=1 end
	  end
	  count
	end

	def sota_activators
	  cals=SotaActivation.where(summit_code: self.code);
	  callsigns=cals.map{|cal| cal.callsign};
	  users=User.where(callsign: callsigns).order(:callsign)
	end

	def sota_chasers
	  cals=SotaChase.where(summit_code: self.code);
	  callsigns=cals.map{|cal| cal.callsign};
	  users=User.where(callsign: callsigns).order(:callsign)
	end

	def activators_including_sota
	  users=self.sota_activators+self.activators
	  users.uniq
	end

	def chasers_including_sota
	  users=self.sota_chasers+self.chasers
	  users.uniq
	end

	def chasers
	  cals=Contact.where("? = ANY(asset1_codes)", self.code);
	  callsigns=cals.map{|cal| u=User.find_by_callsign_date(cal.callsign2, cal.date); if u then u.callsign else nil end};
	  users=User.where(callsign: callsigns).order(:callsign)
	end

	def baggers
	  cals=Contact.where("? = ANY(asset1_codes) or ? = ANY(asset2_codes)", self.code, self.code);
	  callsigns=cals.map{|cal| cal.callsign1};
	  callsigns2=cals.map{|cal| cal.callsign2};
	  users=User.where(callsign: callsigns+callsigns2).order(:callsign)
	end

	def baggers_including_sota
	  users=self.baggers+self.sota_activators
	  users.uniq
	end
	def add_region
	    if self.location then region=Region.find_by_sql [ %q{select id, sota_code, name from regions where ST_Within(ST_GeomFromText('}+self.location.as_text+%q{', 4326), "boundary");} ] else puts "ERROR: place without location. Name: "+self.name+", id: "+self.id.to_s end
	    if self.id and region and region.count>0 and self.region != region.first.sota_code then
	      ActiveRecord::Base.connection.execute("update assets set region='"+region.first.sota_code+"' where id="+self.id.to_s)
	    end

	    if region and region.count>0 and self.region != region.first.sota_code then
	      return region.first.sota_code
	    end
	end

	def add_district
	    if self.location then district=District.find_by_sql [ %q{select id, district_code, name from districts where ST_Within(ST_GeomFromText('}+self.location.as_text+%q{', 4326), "boundary");} ] else puts "ERROR: place without location. Name: "+self.name+", id: "+self.id.to_s end
	    if self.id and district and district.count>0 and self.district != district.first.district_code then
	      ActiveRecord::Base.connection.execute("update assets set district='"+district.first.district_code+"' where id="+self.id.to_s)
	    end

	    if district and district.count>0 and self.district != district.first.district_code then
	      return district.first.district_code
	    end
	end


	def add_links
	    linked_assets=Asset.find_by_sql [ %q{select b.id as id,b.code as code, b.is_active as is_active from assets a inner join assets b on ST_Within(a.location, b.boundary)  where b.area>a.area*0.9 and a.id = }+self.id.to_s ]
	    linked_assets.each do |la|
	      if la.is_active then
		dup=AssetLink.where(:parent_code=> self.code, :child_code => la.code)
        if (!dup or dup.count==0) and la.code!=self.code then
          al=AssetLink.new
          al.parent_code=self.code
          al.child_code=la.code  
          al.save
        end
      end
  end
#    linked_assets=Asset.find_by_sql [ %q{ select b.code as code from assets a inner join assets b on b.is_active=true and ST_Within(b.location, a.boundary)  where a.id = }+self.id.to_s ]
    linked_assets=ActiveRecord::Base.connection.execute( %q{ select b.code as code from assets a inner join assets b on b.is_active=true and ST_Within(b.location, a.boundary)  where (b.area is null or b.area<a.area*1.1) and a.id = }+self.id.to_s )
    linked_assets.each do |la|
        dup=AssetLink.where(:parent_code=> la['code'], :child_code => self.code)
        if (!dup or dup.count==0) and la['code']!=self.code  then
          al=AssetLink.new
          al.child_code=self.code
          al.parent_code=la['code']
          al.save
        end
    end
end

def post_process
  self.add_safecode
  self.add_links
end

def add_safecode
  if self.safecode==nil or self.safecode=="" then
    self.safecode=self.get_safecode
    if self.safecode and self.safecode!="" then self.save end
  end
end

def self.update_all
  a=Asset.first_by_id
  while a do
     a.save
     a=Asset.next(a.id)
     puts a.code
  end
end

def self.first_by_id
  a=Asset.where("id > ?",0).order(:id).first
end


def self.next(id)
  a=Asset.where("id > ?",id).order(:id).first
end

def photos
   ps=AssetPhotoLink.where(asset_code: self.code) 
end

def posted_photos
  posts=Post.where(asset_id: self.id)
  images=[]
  posts.each do |post|
    images=images.concat(post.images)
  end   
  images 
end

def photo_count
  self.photos.count
end


  def self.find_all_hutbagger_photos
     a=Asset.first_by_id
     while a do
       puts a.code
       a.find_hutbagger_photos
       a=Asset.next(a.id)
     end
  end

  def find_hutbagger_photos
   if self.hutbagger_link and self.hutbagger_link.url["http"] then
    url=self.hutbagger_link.url.gsub(/http\:/,"https:")
    page_string = ""
    open(url) do |f|
      page_string = f.read
    end

    got_start=false
    page_string.each_line do |l|
       if l["<h3>Photos</h3>"] then got_start=true end
       if got_start and l["<img src"] then
          fs=l.split('"')
          if fs and fs[1] and fs[1]["img"] then
            link_url="https://hutbagger.co.nz"+fs[1]
            dups=AssetPhotoLink.where(:link_url => link_url, asset_code: self.code)
            if !dups or dups.count==0 then
              hpl=AssetPhotoLink.new
              hpl.asset_code=self.code
              hpl.link_url=link_url
              hpl.save
            end
          end
       end
    end
     true
   end
  end

  def self.add_centroids
    a=Asset.first_by_id
     while a do
       if !a.location then
         puts a.code
         location=a.calc_location
         if location then a.location=location; a.save; end
       end
       a=Asset.next(a.id)
     end
  end


def calc_location
   location=nil
   if self.id then
        locations=Asset.find_by_sql [ 'select id, CASE
                  WHEN (ST_ContainsProperly(boundary, ST_Centroid(boundary)))
                  THEN ST_Centroid(boundary)
                  ELSE ST_PointOnSurface(boundary)
                END AS location from assets where id='+self.id.to_s ]
        if locations and locations.count>0 then location=locations.first.location else location=nil end
   end
   location
end

def self.add_areas
    ActiveRecord::Base.connection.execute( " update assets set area=ST_Area(ST_Transform(boundary,2193)) where boundary is not null and asset_type!='summit'")
end

def add_area
    ActiveRecord::Base.connection.execute( " update assets set area=ST_Area(ST_Transform(boundary,2193)) where boundary is not null and asset_type!='summit' and id="+self.id.to_s)
end

def self.fix_invalid_polygons
    ActiveRecord::Base.connection.execute( "update assets set boundary=st_multi(ST_CollectionExtract(ST_MakeValid(boundary),3)) where id in (select id from assets where ST_IsValid(boundary)=false);")
    ActiveRecord::Base.connection.execute( "update assets set boundary_simplified=st_multi(ST_CollectionExtract(ST_MakeValid(boundary_simplified),3)) where id in (select id from assets where ST_IsValid(boundary_simplified)=false);")
    ActiveRecord::Base.connection.execute( "update assets set boundary_very_simplified=st_multi(ST_CollectionExtract(ST_MakeValid(boundary_very_simplified),3)) where id in (select id from assets where ST_IsValid(boundary_very_simplified)=false);")
end

def self.add_simple_boundaries
    ActiveRecord::Base.connection.execute( 'update assets set boundary_simplified=ST_Simplify("boundary",0.002) where boundary_simplified is null;')
    ActiveRecord::Base.connection.execute( 'update assets set boundary_very_simplified=ST_Simplify("boundary",0.02) where boundary_very_simplified is null;')
    ActiveRecord::Base.connection.execute( 'update assets set boundary_quite_simplified=ST_Simplify("boundary",0.002) where boundary_quite_simplified is null;')
end

def add_simple_boundary
    ActiveRecord::Base.connection.execute( 'update assets set boundary_simplified=ST_Simplify("boundary",0.002) where id='+self.id.to_s+';')
    ActiveRecord::Base.connection.execute( 'update assets set boundary_very_simplified=ST_Simplify("boundary",0.02) where id='+self.id.to_s+';')
    ActiveRecord::Base.connection.execute( 'update assets set boundary_quite_simplified=ST_Simplify("boundary",0.002) where id='+self.id.to_s+';')
end

def self.get_altitudes_from_sota
  summits=Asset.where(asset_type: "summit")
  summits.each do |summit|
    puts "Summit: "+summit.code
    url = "https://api-db.sota.org.uk/admin/find_summit?search="+summit.code
    data = JSON.parse(open(url, {ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE}).read)
    if data and data[0] then
      summitId=data[0]["SummitId"]
      url = "https://api-db.sota.org.uk/admin/summit_history?summitID="+summitId.to_s
      data = JSON.parse(open(url, {ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE}).read)
      if data and data["info"] and data["info"].count>0 and data["info"][0]["AltM"] then
        puts data["info"][0]["AltM"]
        summit.altitude=data["info"][0]["AltM"].to_i
        summit.save
      end
    end
  end
end

def self.add_sota_activation_zones
     count=0
     a=Asset.first_by_id
     while a do
       count+=1
       a.add_sota_activation_zone
       a=Asset.next(a.id)
     end
end

def add_sota_activation_zone
  if self.asset_type=="summit" then
    puts self.code
    dem=Asset.get_custom_connection("cps",'dem30','mbriggs','littledog')
    location=self.location
    alt_min=self.altitude-25
    alt_max=5000
    dist_max=0.02 #degrees
    puts " select val, st_astext(geom) as geom from (select (st_dumpaspolygons(st_reclass(st_union(st_clip(rast,  st_buffer(ST_GeomFromText('POINT(#{self.location.x} #{self.location.y})',4326),#{dist_max}))),1,'0-#{alt_min}:0,#{alt_min}-#{alt_max}:1','8BUI'))).* from dem30s) as foo where val=1 and st_contains(geom, ST_GeomFromText('POINT(#{self.location.x} #{self.location.y})',4326));"
    az_poly=dem.exec_query(" select val, st_astext(geom) as geom from (select (st_dumpaspolygons(st_reclass(st_union(st_clip(rast,  st_buffer(ST_GeomFromText('POINT(#{self.location.x} #{self.location.y})',4326),#{dist_max}))),1,'0-#{alt_min}:0,#{alt_min}-#{alt_max}:1','8BUI'))).* from dem30s) as foo where val=1 and st_contains(geom, ST_GeomFromText('POINT(#{self.location.x} #{self.location.y})',4326));")   
    if az_poly and az_poly.count>0 and az_poly.first["geom"] then
      puts az_poly.first["geom"]
      boundary=make_multipolygon(az_poly.first["geom"])
      ActiveRecord::Base.connection.execute("update assets set boundary=ST_geomfromtext('#{boundary}',4326) where id=#{self.id.to_s};");  
    end
  end
end

def make_multipolygon(boundary)
   if boundary[0..6]=="POLYGON" then boundary="MULTIPOLYGON ("+boundary[7..-1]+")" end
   boundary
end

def self.get_custom_connection(identifier, dbname, dbuser, password)
      eval("Custom_#{identifier} = Class::new(ActiveRecord::Base)")
      eval("Custom_#{identifier}.establish_connection(:adapter=>'postgis', :database=>'#{dbname}', " +
      ":username=>'#{dbuser}', :password=>'#{password}')")
    return eval("Custom_#{identifier}.connection")
end

def get_access
  #roads
  ActiveRecord::Base.connection.execute("update assets set access_road_ids=(select array_agg(r.id) as road_ids from assets a, roads r where (ST_intersects (a.boundary, r.linestring) or ST_intersects (a.location, r.linestring)) and a.code='#{self.code}') where code='#{self.code}'")
 
  #legal_roads
  ActiveRecord::Base.connection.execute("update assets set access_legal_road_ids=(select array_agg(r.id) as legal_road_ids from assets a, legal_roads r where (ST_intersects (a.boundary, r.boundary) or ST_intersects (a.location, r.boundary)) and a.code='#{self.code}') where code='#{self.code}'")

  #parks
  ActiveRecord::Base.connection.execute("update assets set access_park_ids=(select array_agg(r.id) as park_ids from assets a, assets r where (ST_intersects (a.boundary, r.boundary) or ST_intersects (a.location, r.boundary)) and a.code='#{self.code}' and r.asset_type='park') where code='#{self.code}'")

  #tracks
  ActiveRecord::Base.connection.execute("update assets set access_track_ids=(select array_agg(r.id) as track_ids from assets a, doc_tracks r where (ST_intersects (a.boundary, r.linestring) or ST_intersects (a.location, r.linestring)) and a.code='#{self.code}') where code='#{self.code}'")

  self.reload
  if self.access_legal_road_ids==nil and self.access_track_ids==nil and self.access_park_ids==nil then 
    ActiveRecord::Base.connection.execute("update assets set public_access=false where code='#{self.code}'")
  else
    ActiveRecord::Base.connection.execute("update assets set public_access=true where code='#{self.code}'")
  end
  self.reload
end

def get_access_with_buffer(buffer)
  if self.boundary then
     queryfield='a.boundary'
  else
     queryfield='a.location'
  end

  #roads
  ActiveRecord::Base.connection.execute("update assets set access_road_ids=(select array_agg(r.id) as road_ids from assets a, roads r where ST_DWithin(ST_Transform(#{queryfield},2193), ST_Transform(r.linestring,2193), #{buffer}) and a.code='#{self.code}') where code='#{self.code}'")
 
  #legal_roads
  ActiveRecord::Base.connection.execute("update assets set access_legal_road_ids=(select array_agg(r.id) as legal_road_ids from assets a, legal_roads r where ST_DWithin(ST_Transform(#{queryfield},2193), ST_Transform(r.boundary,2193), #{buffer}) and a.code='#{self.code}') where code='#{self.code}'")

  #parks
  ActiveRecord::Base.connection.execute("update assets set access_park_ids=(select array_agg(r.id) as park_ids from assets a, assets r where ST_DWithin(ST_Transform(#{queryfield},2193), ST_Transform(r.boundary,2193), #{buffer}) and a.code='#{self.code}' and r.asset_type='park') where code='#{self.code}'")

  #tracks
  ActiveRecord::Base.connection.execute("update assets set access_track_ids=(select array_agg(r.id) as track_ids from assets a, doc_tracks r where ST_DWithin(ST_Transform(#{queryfield},2193), ST_Transform(r.linestring,2193), #{buffer}) and a.code='#{self.code}') where code='#{self.code}'")

  self.reload
  if self.access_legal_road_ids==nil and self.access_track_ids==nil and self.access_park_ids==nil then 
    ActiveRecord::Base.connection.execute("update assets set public_access=false where code='#{self.code}'")
  else
    ActiveRecord::Base.connection.execute("update assets set public_access=true where code='#{self.code}'")
  end
  self.reload
end

def self.get_sota_access
  as=Asset.where(asset_type: 'summit')
  as.each do |a|
    puts a.code
    a.get_access
  end
end

def self.get_lake_access
  as=Asset.where(asset_type: 'lake')
  as.each do |a|
    puts a.code
    a.get_access_with_buffer(500)
  end
end

end

