class Asset < ActiveRecord::Base

 after_save :post_process
 validates :code, presence: true, uniqueness: true
 validates :name, presence: true

def boundary_simple
   pp=Asset.find_by_sql [ "select id, ST_NPoints(boundary) as altitude from assets where id="+self.id.to_s ]
   if pp then 
     lenfactor=Math.sqrt(pp.first.altitude/10000)
     rnd=0.000002*10**lenfactor
     boundarys=Asset.find_by_sql [ 'select id, ST_AsText(ST_Simplify("boundary", '+rnd.to_s+')) as "boundary" from assets where id='+self.id.to_s ]  
     boundary=boundarys.first.boundary
     boundary
   else nil end
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

def self.get_next_code(asset_type)
  newcode=nil
  if asset_type=='hut' then prefix='ZLH/' end
  if asset_type=='park' then prefix='ZLP/' end
  if asset_type=='island' then prefix='ZLI/' end

  if prefix then 
    last_asset=Asset.where(:asset_type => asset_type).order(:code).last
    codestring=last_asset.code[3..-1]
    codenumber=codestring.to_i
    codenumber+=1
    newcode=prefix+(codenumber.to_s.rjust(codestring.length,'0'))
  end
  newcode
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
  AssetType.find_by(name: self.asset_type)
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
  als=AssetLink.where(parent_code: self.code)
  codes=als.map{|al| al.child_code}
  assets=Asset.where(:code => codes, is_active: true)
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

def self.assets_from_code(codes)
  assets=[]
  if codes then 
  code_arr=codes.split(',') 
  code_arr.each do |code|
    code=code.lstrip
    asset={asset: nil, code: nil, name: nil, url: nil, external: nil, type: nil}
    if code then
      code=code.upcase
      a=Asset.find_by(code: code)
      if a then
          asset[:asset]=a
          asset[:url]=a.url
          asset[:name]=a.name
          asset[:external]=false
          asset[:code]=a.code
          asset[:type]=a.asset_type
          asset[:title]=a.type.display_name
      elsif code.match(/^[a-zA-Z]{1,2}-\d{4}/)  then
        #POTA
        if code[0..1].upcase=='VK' then
          asset[:name]=code
          asset[:url]='https://parksnpeaks.org/getPark.php?actPark='+code+'&submit=Process'
          asset[:external]=true
          asset[:code]=code
          asset[:type]='park'
          asset[:title]="POTA - VK"
        else
          asset[:name]=code
          asset[:url]='http://pota.us/#/parks/'+code
          asset[:external]=true
          asset[:code]=code
          asset[:type]='park'
          asset[:title]="POTA"
        end  
      elsif code.match(/^[a-zA-Z]{1,2}[fF]{2}-\d{4}/) then
        #WWFF
        if code[0..1].upcase=='VK' then
          asset[:name]=code
          asset[:url]='https://parksnpeaks.org/getPark.php?actPark='+code+'&submit=Process'
          asset[:external]=true
          asset[:code]=code
          asset[:type]='park'
            asset[:title]="WWFF - VK"
        else
          asset[:name]=code
          asset[:url]='http://wwff.co/directory/'
          asset[:external]=true
          asset[:code]=code
          asset[:type]='park'
          asset[:title]="WWFF"
        end
      elsif code.match(/^[a-zA-Z]{1,2}\d\/[a-zA-Z]{2}-\d{3}/) then
        #SOTA
        asset[:name]=code
        asset[:url]="https://summits.sota.org.uk/summit/"+code
        asset[:external]=true
        asset[:code]=code
        asset[:type]='summit'
        asset[:title]="SOTA"
      end
      assets.push(asset)
   end 
  end 
  end
  assets

end

def self.get_pnp_class_from_code(code)
  aa=Asset.assets_from_code(code)
  a=aa.first 
  pnp_class="QRP" 
  if a and a[:type] then 
     ac=AssetType.find_by(name: a[:type])
     pnp_class=ac.pnp_class
  elsif a[:title][0..3]=="WWFF" then pnp_class="WWFF"
  elsif a[:title][0..3]=="POTA" then pnp_class="POTA"
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

def self.url_from_code(code)
  url=nil
  external=false
  if code[0..4]=="VKFF-" then
    #wwff - VK
    url="https://parksnpeaks.org/getPark.php?actPark="+code[0..8]+"&submit=Process"
    external=true
  elsif code[0..4]=="ZLFF-" then
    #wwff - NZ
    pp=WwffPark.find_by(code: code[0..8])
    if pp then url="/parks/"+pp.napalis_id.to_s end
  elsif code[0..2]=="ZL-" then
    #POTA NZ
    pp=PotaPark.find_by(reference: code[0..6])
    if pp then url="/parks/"+pp.park_id.to_s end
  elsif code[0..2]=="VK-" then
    #POTA VK
    url="https://parksnpeaks.org/getPark.php?actPark="+code[0..6]+"&submit=Process"
    external=true
  elsif code[0..3]=="ZLP/" then
    #ZLOTA Park
    park=Park.find_by(id: code[4..10])
    if park then url="/parks/"+park.id.to_s end
  elsif code[0..3]=="ZLH/" then
    #ZLOTA hut
    hut=Hut.find_by(id: code[4..7])
    if hut then url="/huts/"+hut.id.to_s end
  elsif code[0..3]=="ZLI/" then
    #ZLOTA island
    island=Island.find_by(id: code[4..8])
    if island then url="/islands/"+island.id.to_s end
  elsif code.scan(/ZL\d\//).length>0 then
    #NZ SOTA
    summit=SotaPeak.find_by(summit_code: code[0..9])
    if summit then url="/summits/"+summit.short_code end
  elsif code.scan(/VK\d\//).length>0 then
    #VK SOTA
    url="https://summits.sota.org.uk/summit/"+code[0..10]
    external=true
  end
  {url: url, external: external}
end

def self.add_parks
  ps=Park.all
  ps.each do |p|
    a=Asset.find_by(asset_type: 'park', code: p.code)
    if !a then a=Asset.new end
    a.asset_type="park"
    a.code=p.code
    a.url='/parks/'+p.id.to_s
    a.name=p.name_
    a.description=p.description
    a.is_active=p.is_active and not p.is_mr
    a.boundary=p.boundary
    if p.doc_park then 
       a.boundary=p.doc_park.WKT 
    end
    a.category=p.owner
    a.location=p.location
    a.save
    puts a.code
  end 
  true
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
    a.code=p.code
    a.url='/islands/'+p.id.to_s
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
    if !a then a=Asset.new end
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

def self.add_pota_park(p)
    a=Asset.find_by(asset_type: 'pota park', code: p.reference)
    if !a then a=Asset.new end
    a.asset_type="pota park"
    a.code=p.reference
    if p.park then
      a.url='/parks/'+p.park.id.to_s
      a.is_active=p.park.is_active
    else
      a.is_active=true
    end
    a.name=p.name
    a.location=p.location
    if p.park then
      if  p.park.doc_park then a.boundary=p.park.doc_park.WKT else a.boundary=p.park.boundary end end
    a.save
    puts a.code
    a
end

def self.add_wwff_parks
  ps=WwffPark.all
  ps.each do |p|
    Asset.add_wwff_park(p)
  end
end

def self.add_wwff_park(p)
    a=Asset.find_by(asset_type: 'wwff park', code: p.code)
    if !a then a=Asset.new end
    a.asset_type="wwff park"
    a.code=p.code
    if p.park then 
      a.url='/parks/'+p.park.id.to_s
      a.is_active=p.park.is_active
    end
    a.name=p.name
    a.location=p.location
    if p.park then 
      if p.park.doc_park then a.boundary=p.park.doc_park.WKT else a.boundary=p.park.boundary end 
    end
    a.save
    puts a.code
    a
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

def activators
  cals=Contact.where("? = ANY(asset1_codes)", self.code);
  callsigns=cals.map{|cal| cal.callsign1};
  users=User.where(callsign: callsigns).order(:callsign)
end

def chasers
  cals=Contact.where("? = ANY(asset2_codes)", self.code);
  callsigns=cals.map{|cal| cal.callsign2};
  users=User.where(callsign: callsigns).order(:callsign)
end

def baggers
  cals=Contact.where("? = ANY(asset1_codes) or ? = ANY(asset2_codes)", self.code, self.code);
  callsigns=cals.map{|cal| cal.callsign1};
  callsigns2=cals.map{|cal| cal.callsign2};
  users=User.where(callsign: callsigns+callsigns2).order(:callsign)
end



def add_links
    linked_assets=Asset.find_by_sql [ %q{select b.id as id,b.code as code from assets a inner join assets b on ST_Within(a.location, b.boundary) where a.id = }+self.id.to_s ]
    linked_assets.each do |la|
      dup=AssetLink.where(:parent_code=> self.code, :child_code => la.code)
      if !dup or dup.count==0 and la!=self then
        al=AssetLink.new
        al.parent_code=self.code
        al.child_code=la.code  
        al.save
      end
  end
    linked_assets=Asset.find_by_sql [ %q{select b.id as id, b.code as code from assets a inner join assets b on ST_Within(b.location, a.boundary) where a.id = }+self.id.to_s ]
    linked_assets.each do |la|
      dup=AssetLink.where(:parent_code=> self.code, :child_code => la.code)
      if !dup or dup.count==0 and la!=self then
        al=AssetLink.new
        al.parent_code=self.code
        al.child_code=la.code
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

end
