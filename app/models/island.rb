class Island < ActiveRecord::Base

  def get_code
    code="ZLI/"+self.id.to_s.rjust(5,'0')
  end

  def codename
    codename=self.code+" - "+self.name
  end

def huts
   hs=[]
#   if self.boundary then 
#     hs=Hut.find_by_sql [ "select * from huts h where ST_Within(h.location, ST_GeomFromText('"+self.simple_boundary+"',4326));" ]
#   end
   hs=Hut.find_by_sql [ "select * from huts where island_id = "+self.id.to_s]
   hs

end

def baggers
      contacts1=Contact.find_by_sql [ "select * from contacts where island1_id="+self.id.to_s+" or island2_id="+self.id.to_s  ]

      contacts=[]

      contacts1.each do |contact|
        if contact.callsign1 then contacts.push(contact.callsign1) end
        if contact.callsign2 then contacts.push(contact.callsign2) end
      end

      contacts=contacts.uniq

      users=User.where(callsign: contacts).order(:callsign)
end

def contacts
      contacts1=Contact.find_by_sql [ "select * from contacts where island1_id="+self.id.to_s+" or island2_id="+self.id.to_s  ]
end

def boundary
  poly=IslandPolygon.where(name_id: self.name_id)
  if poly and poly.count>0 then boundary=poly.first.WKT else boundary=nil end
  boundary
end

def simple_boundary
   boundary=nil
   if self.id then
       rnd=0.0002
       boundarys=IslandPolygon.find_by_sql [ 'select name_id, ST_AsText(ST_Simplify("WKT", '+rnd.to_s+')) as "WKT" from island_polygons where name_id='+self.name_id.to_s ]
       if boundarys and boundarys.count>0 then boundary=boundarys.first.WKT end
   end
   boundary
end

def has_polygon
   hp=false
   counts=IslandPolygon.find_by_sql [ 'select count(id) as id from island_polygons where name_id='+self.name_id.to_s ]
   if counts and counts.length>0 then 
     count=counts.first.id 
     if count>0 then hp=true end 
   end
end
  def summits
    pps=SotaPeak.where(:island_id => self.id)
  end

  def self.add_codes
     ps=Island.all
     ps.each do |p|
       p.code=p.get_code
       p.save
     end
  end

end

