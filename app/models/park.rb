class Park < ActiveRecord::Base

#  set_rgeo_factory_for_column(:boundary, RGeo::Geographic.spherical_factory(:srid => 4326, :proj4=> '+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs', :has_z_coordinate => false))

#single 7-digit sequence base don napalis_id
  def get_code
    code="ZLP/"+self.id.to_s.rjust(7,'0')
  end

#ZLP/XX-#### code based on region
  def self.add_dist_codes
     parks=Park.find_by_sql [ " select id,name,region from parks where dist_code='' or dist_code is null order by coalesce(ST_Area(boundary),0) desc" ]
     parks.each do |p|
       code=self.get_next_dist_code(p.region) 
       ActiveRecord::Base.connection.execute("update parks set dist_code='"+code+"' where id="+p.id.to_s+";")
       puts code +" - "+p.name
     end 
  end

  def self.get_next_dist_code(region)
    if !region or region=='' then region='ZZ' end
    last_codes=Park.find_by_sql [ " select dist_code from parks where dist_code like 'ZLP/"+region+"-%%' and dist_code is not null order by dist_code desc limit 1;" ]
    if last_codes and last_codes.count>0 and last_codes.first.dist_code then 
      last_code=last_codes.first.dist_code
    else 
      last_code='ZLP/'+region+"-0000"
    end
    next_code=last_code[0..6]+(((last_code[7..10].to_i)+1).to_s.rjust(4,'0'))
    next_code
  end

  def codename
    codename=self.code+" - "+self.name
  end

  def doc_park
    #dp=Docparks.find_by_id(self.id) 
    dp=Crownpark.find_by(napalis_id: self.id) 
  end


  def self.add_centroids
    ps=Park.all
    ps.each do |p|
      location=p.calc_location
      if location then p.location=location; p.save; end 
    end
    true
  end




def self.add_regions
     count=0
     a=Park.first_by_id
     while a do
       #puts a.code+" "+count.to_s
       count+=1
       a.add_region
       a=Park.next(a.id)
     end
end

def add_region
      if self.location then region=Region.find_by_sql [ %q{ SELECT * 
       FROM regions dp
       WHERE ST_DWithin(ST_GeomFromText('}+self.location.as_text+%q{', 4326), boundary, 20000, false) 
       ORDER BY ST_Distance(ST_GeomFromText('}+self.location.as_text+%q{', 4326), boundary) LIMIT 50; } ]
      else puts "ERROR: place without location. Name: "+self.name+", id: "+self.id.to_s end

    if region and region.count>0 and (not (self.region==nil or self.region=="")) and self.region!=region.first.sota_code  then
       puts "Not overwriting mismatched regions: "+self.code+" "+self.name+" "+self.region+" "+region.first.sota_code
    end

    if region and region.count>0 and (self.region==nil or self.region=="")  then
      ActiveRecord::Base.connection.execute("update parks set region='"+region.first.sota_code+"', dist_code=null where id="+self.id.to_s)
      puts "updating record "+self.id.to_s+" "+self.name
    end

end
 
  def self.merge_crownparks
    count=0
    hundreds=0
    #parks=Docparks.all
    parks=Crownpark.find_by_sql [ " select id from crownparks; " ]
    cc=0
    uc=0

    parks.each do |pid|
      park=Crownpark.find_by_id(pid.id)
      count+=1
      if count>=100 then 
          count=0
          hundreds+=1
          puts "Records: "+(hundreds*100).to_s
      end

      #p=self.find_by_id(park.NaPALIS_ID)
      p=self.find_by_id(park.napalis_id)
      #create if needed
      if not p then
        #p=self.create(id: park.NaPALIS_ID, name: park.Name)
        p=self.create(id: park.napalis_id, name: park.name)
        cc=cc+1
      end

      #update atrribtes
      #if park.Section=="S24_3_FIXED_MARGINAL_STRIP" or park.Local_Purp!=nil then
      if park.section=="s.24(3) - Fixed Marginal Strip" or park.section== "s.23 - Local Purpose Reserve" or park.section=="s.22 - Government Purpose Reserve" or park.section=="s.176(1)(a) - Unoccupied Crown Land" or park.name.upcase["GRAVEL"] then
        p.is_mr=true
      else
        p.is_mr=false
      end
      if park.ctrl_mg_vst==nil or park.ctrl_mg_vst.upcase=="NO" or park.ctrl_mg_vst.upcase=="NULL" then
        p.owner="DOC"
      else
        p.owner=park.ctrl_mg_vst
      end
      p.is_active=park.is_active
      p.master_id = park.master_id
      if !p.location then p.location=p.calc_location end
      if !p.code then p.code=p.get_code end
      pa=Park.find_by_sql [ "select ST_Area(boundary)  as area from parks where id="+p.id.to_s ]
      cpa=Crownpark.find_by_sql [ 'select ST_Area("WKT") as area from crownparks where id='+park.id.to_s ]
      if pa.first.area != cpa.first.area then
        print "#"; $stdout.flush
        p.boundary=park.WKT
        p.save
      else
        print "."; $stdout.flush
        ActiveRecord::Base.connection.execute("update parks set id="+p.id.to_s+", name='"+p.name.gsub("'","''")+"', is_mr="+p.is_mr.to_s+", owner='"+p.owner.gsub("'","''")+"', is_active="+p.is_active.to_s+", master_id="+(if p.master_id then p.master_id.to_s else "null" end)+", location=ST_GeomFromText('"+(p.location||"").as_text+"', 4326), code='"+p.code+"' where id="+p.id.to_s) 
      end
      uc=uc+1
      #p.add_region
    end



    puts "Created "+cc.to_s+" rows, updated "+uc.to_s+" rows"
    true
  end

  def all_boundary
   if self.boundary==nil then
       #boundarys=Docparks.find_by_sql [ 'select id, ST_AsText("WKT") as "WKT" from docparks where id='+self.id.to_s ] 
       boundarys=Crownpark.find_by_sql [ 'select id, ST_AsText("WKT") as "WKT" from crownparks where napalis_id='+self.id.to_s ] 
       if boundarys and boundarys.count>0 then boundary=boundarys.first.WKT else boundary=nil end
   else
     boundary=self.boundary
   end
   if boundary then boundary else "" end
  end
  
  def simple_boundary
   boundary=nil
   if self.id then 
     if self.boundary==nil then
       rnd=0.0002
       #boundarys=Docparks.find_by_sql [ 'select id, ST_AsText(ST_Simplify("WKT", '+rnd.to_s+')) as "WKT" from docparks where id='+self.id.to_s ] 
       boundarys=Crownpark.find_by_sql [ 'select id, ST_AsText(ST_Simplify("WKT", '+rnd.to_s+')) as "WKT" from crownparks where napalis_id='+self.id.to_s ] 
       if boundarys and boundarys.count>0 then boundary=boundarys.first.WKT else boundary=nil end
     else
       boundary=self.boundary
     end
    end
   if boundary then boundary else "" end

  end
  def calc_location
   location=nil
   if self.id then
     if self.boundary==nil then
#        locations=Docparks.find_by_sql [ 'select id, ST_Centroid("WKT") as "WKT" from docparks where id='+self.id.to_s ] 
        locations=Crownpark.find_by_sql [ 'select id, CASE
                  WHEN (ST_ContainsProperly("WKT", ST_Centroid("WKT")))
                  THEN ST_Centroid("WKT")
                  ELSE ST_PointOnSurface("WKT")
                END AS  "WKT" from crownparks where napalis_id='+self.id.to_s ] 
        if locations and locations.count>0 then location=locations.first.WKT else location=nil; puts "ERROR: failed to find "+self.id.to_s end
     else
        locations=Park.find_by_sql [ 'select id, CASE
                  WHEN (ST_ContainsProperly(boundary, ST_Centroid(boundary)))
                  THEN ST_Centroid(boundary)
                  ELSE ST_PointOnSurface(boundary)
                END AS location from parks where id='+self.id.to_s ] 
        if locations and locations.count>0 then location=locations.first.location else location=nil end
     end
   end
   location
  end
  
  def self.prune_parks(test)
   ops=[]
   ps=Park.all
   ps.each do |p| 
     cps=Crownpark.where(:napalis_id => p.id)
     if cps and cps.count>0 then

     else
       if p.boundary==nil then
         puts "Orphan found :"+p.id.to_s
         ops.push(p.id)
         if !test then p.is_active=false; p.save end
       else
         puts "Local definition found :"+p.id.to_s
       end
     end
   end
   ops
  end
     
  def wwff_park
    pps=WwffPark.where(:napalis_id => self.id)
    if pps then pps.first else nil end
  end

  def pota_park
    pps=PotaPark.where(:park_id => self.id)
    if pps then pps.first else nil end
  end

  def summits
    pps=SotaPeak.where(:park_id => self.id)
  end

  def huts
  # hs=Hut.find_by_sql [ "select * from huts h where ST_Within(h.location, ST_GeomFromText('"+self.all_boundary.as_text+"',4326));" ]
   hs=Hut.find_by_sql [ "select * from huts where park_id = "+self.id.to_s]
   hs
  end

  def contacts
      contacts1=Contact.find_by_sql [ "select * from contacts where park1_id='"+self.id.to_s+"' or park2_id='"+self.id.to_s+"'"  ]
  end

  def baggers
      contacts1=Contact.find_by_sql [ "select * from contacts where park1_id='"+self.id.to_s+"' or park2_id='"+self.id.to_s+"'"  ]

      contacts=[]

      contacts1.each do |contact|
        if contact.callsign1 then contacts.push(contact.callsign1) end
        if contact.callsign2 then contacts.push(contact.callsign2) end
      end

      contacts=contacts.uniq

      users=User.where(callsign: contacts).order(:callsign)
  end

  def self.add_codes
     ps=Park.all
     ps.each do |p|
       if !p.code then 
         p.code=p.get_code
         p.save
       end
     end
  end

def self.first_by_id
  a=Park.where("id > ?",0).order(:id).first
end


def self.next(id)
  a=Park.where("id > ?",id).order(:id).first
end

def self.add_ak_parks
  ps=AkMaps.all
  ps.each do |park|
    if park.code and park.code!='' then p=Park.find_by(dist_code: park.code) else p=nil end
    if !p then p=Park.new; puts "New park" end
    p.name=park.name
    p.boundary=park.WKT
    p.dist_code=park.code
    p.is_active=true
    p.is_mr=false
    p.owner="Auckland Regional Council"
    p.location=park.location 
    p.save
    p.add_region
    p.reload
    if p.dist_code==nil or p.dist_code=="" then
      p.dist_code=Park.get_next_dist_code(p.region)
      p.save
    end
    puts "Added park :"+p.id.to_s+" - "+p.name
  end
end

end
   
