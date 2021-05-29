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

def self.get_polygons
  ls=Island.where(is_active: true)
  ls.each do |l|
    islands=IslandPolygon.find_by_sql [ %q{select * from island_polygons where is_active=true and ST_Within(ST_GeomFromText('}+l.WKT.as_text+%q{',4326), boundary);} ]
    if !islands or islands.count==0 then
      islands=IslandPolygon.find_by_sql [ %q{ SELECT * 
       FROM island_polygons dp
       WHERE is_active=true and ST_DWithin(ST_GeomFromText('}+l.WKT.as_text+%q{', 4326), boundary, 5000, false) 
       ORDER BY ST_Distance(ST_GeomFromText('}+l.WKT.as_text+%q{', 4326), boundary) LIMIT 50; } ]
    end
    if islands and islands.count>0 then
      found=false
      islands.each do |island|
        l_name=l.name.gsub('ū','u')
        l_name=l_name.gsub(' / ',' ')
        l_name=l_name.gsub('/',' ')
        l_name=l_name.gsub(' (',' ')
        l_name=l_name.gsub(' (',' ')
        l_name=l_name.gsub(')',' ')
        l_name=l_name.gsub(')',' ')
        l_name=l_name.gsub(/[^0-9a-z]/i, '').gsub('Islands','').gsub('Island','')
        island_name=island.name.gsub('ū','u')
        island_name=island_name.gsub(' / ',' ')
        island_name=island_name.gsub('/',' ')
        island_name=island_name.gsub(' (',' ')
        island_name=island_name.gsub(' (',' ')
        island_name=island_name.gsub(')',' ')
        island_name=island_name.gsub(')',' ')
        island_name=island_name.gsub(/[^0-9a-z]/i, '').gsub('Islands','').gsub('Island','')
        island_arr=island_name.split(' ').sort
        l_arr=l_name.split(' ').sort

        if found==false and ( l_name==island_name or island_arr & l_arr == l_arr  or island_arr & l_arr == island_arr or l_name.include? island_name or island_name.include? l_name) then

          if l.name != island.name then puts "Matched "+(l.name||"unnamed")+" with "+(island.name||"unnamed") end
          l.boundary=island.boundary
          l.save
          found=true
        end
      end
      if found==false then puts "Failed to find "+(l.name||"unnamed")+". Best was "+ islands.first.name end
    end
  end
 true
end










def self.import
  Nzgdb.where(feat_type: 'island', is_active: true).all do |ni|
     i=Island.find_by(name_id: ni.id)
     if !i then 
       i=Island.new(ni.attributes.except(:id)) 
       puts "New: "+i.name
     else
       i.assign_attributes(ni.attributes.except(:code, :id))
     end
     if !i.code then
       i.code="ZLI/"+i.name_id.rjust(5,'0')
       puts "Added entry: "+i.code
     end
     #i.save
  end

  Island.all.each do |i|
    nz=Nzgdb.find_by(name_id: i.id, is_active: true)
    if !nz then
        puts "DELETE: "+i.name+" - "+(if i.is_active==true then "ACTIVE" else "INACTIVE" end)
        i.is_active=false
    end
    #i.save
  end; true
end

end

