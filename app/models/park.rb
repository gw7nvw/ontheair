class Park < ActiveRecord::Base

  set_rgeo_factory_for_column(:boundary, RGeo::Geographic.spherical_factory(:srid => 4326, :proj4=> '+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs', :has_z_coordinate => false))

  def doc_park
    #dp=Docparks.find_by_id(self.id) 
    dp=Crownparks.find_by(napalis_id: self.id) 
  end

  def self.update_table
    #parks=Docparks.all
    parks=Crownparks.all
    cc=0
    uc=0

    parks.each do |park|
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
      if park.section=="s.24(3) - Fixed Marginal Strip" or park.section== "s.23 - Local Purpose Reserve" or park.section=="s.22 - Government Purpose Reserve" or park.section=="s.176(1)(a) - Unoccupied Crown Land" then
        p.is_mr=true
      else
        p.is_mr=false
      end
      if park.ctrl_mg_vst==nil or park.ctrl_mg_vst.upcase=="NO" or park.ctrl_mg_vst.upcase=="NULL" then
        p.owner="DOC"
      else
        p.owner=park.ctrl_mg_vst
      end

      p.save
      uc=uc+1
    end
    puts "Created "+cc.to_s+" rows, updated "+uc.to_s+" rows"
    true
  end

  def all_boundary
   if self.boundary==nil then
       #boundarys=Docparks.find_by_sql [ 'select id, ST_AsText("WKT") as "WKT" from docparks where id='+self.id.to_s ] 
       boundarys=Crownparks.find_by_sql [ 'select id, ST_AsText("WKT") as "WKT" from crownparks where napalis_id='+self.id.to_s ] 
       boundary=boundarys.first.WKT
   else
     boundary=self.boundary
   end
   boundary
  end
  
  def simple_boundary
   boundary=nil
   if self.id then 
     if self.boundary==nil then
       rnd=0.0002
       #boundarys=Docparks.find_by_sql [ 'select id, ST_AsText(ST_Simplify("WKT", '+rnd.to_s+')) as "WKT" from docparks where id='+self.id.to_s ] 
       boundarys=Crownparks.find_by_sql [ 'select id, ST_AsText(ST_Simplify("WKT", '+rnd.to_s+')) as "WKT" from crownparks where napalis_id='+self.id.to_s ] 
       boundary=boundarys.first.WKT
     else
       boundary=self.boundary
     end
    end
    boundary
  end
  def location
   location=nil
   if self.id then
     if self.boundary==nil then
#        locations=Docparks.find_by_sql [ 'select id, ST_Centroid("WKT") as "WKT" from docparks where id='+self.id.to_s ] 
        locations=Crownparks.find_by_sql [ 'select id, ST_Centroid("WKT") as "WKT" from crownparks where napalis_id='+self.id.to_s ] 
        if locations then location=locations.first.WKT else location=nil end
     else
        locations=Park.find_by_sql [ 'select id, ST_Centroid("boundary") as "boundary" from parks where napalis_id='+self.id.to_s ] 
        if locations then location=locations.first.boundary else location=nil end
     end
   end
   location
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
      contacts1=Contact.find_by_sql [ "select * from contacts where park1_id="+self.id.to_s+" or park2_id="+self.id.to_s  ]
  end

  def baggers
      contacts1=Contact.find_by_sql [ "select * from contacts where park1_id="+self.id.to_s+" or park2_id="+self.id.to_s  ]

      contacts=[]

      contacts1.each do |contact|
        if contact.callsign1 then contacts.push(contact.callsign1) end
        if contact.callsign2 then contacts.push(contact.callsign2) end
      end

      contacts=contacts.uniq

      users=User.where(callsign: contacts).order(:callsign)
  end

end
