class Lake < ActiveRecord::Base
require 'csv'

    establish_connection "lakes"

def self.import(filename)
  CSV.foreach(filename, :headers => true) do |row|
    h=row.to_hash
    boundary=h.first[1]
    if boundary[0..6]=="POLYGON" then boundary="MULTIPOLYGON ("+boundary[8..-1]+")" end
    dup=Lake.find_by(topo50_fid: h['t50_fid'])
    if !dup then 
       l=Lake.create(name: h['name'], topo50_fid: h['t50_fid'], boundary: boundary )
       print '.'; $stdout.flush
    end
  end
  true
end

def self.mark()
  Nzgdb.where(feat_type: 'Lake').each do |place|
    lakes=Lake.find_by_sql [ %q{select * from lakes where ST_Within(ST_GeomFromText('}+place.WKT.as_text+%q{',4326), boundary);} ]
    if !lakes or lakes.count==0 then 
      print '#'; $stdout.flush
      lakes=Lake.find_by_sql [ %q{ SELECT * 
       FROM lakes dp
       WHERE ST_DWithin(ST_GeomFromText('}+place.WKT.as_text+%q{', 4326), boundary, 5000, false) 
       ORDER BY ST_Distance(ST_GeomFromText('}+place.WKT.as_text+%q{', 4326), boundary) LIMIT 50; } ]
    end

    if lakes and lakes.count>0 then 
      found=false
      lakes.each do |lake|
        if found==false and (place.name==lake.name or lake.name==nil) then
          print '.'; $stdout.flush
        #  puts "Matched "+(place.name||"unnamed")+" with "+(lake.name||"unnamed")
          lake.is_active=true
          lake.name=place.name
          lake.save
          found=true
        end
      end
      if found==false then puts "Failed to find "+place.name||"unnamed" end
    end
  end 

  ls=Lake.where('name is not null')
  ls.each do |l|
    l.is_active=true
    l.save
  end
  true

end

def self.remove_duplicates
  Lake.where(is_active: true).each do |l|
    l.reload
    if l.is_active then       
      print '.'; $stdout.flush

      ls=Lake.find_by_sql [ "select l2.* from lakes l1 inner join lakes l2 on ST_Touches(l1.boundary, l2.boundary) is true where l1.code='"+l.code+"';"] 
      if ls and ls.count>0 then
        lb=l.boundary.as_text.gsub(')))','))')
        ls.each do |l2|
          l2b=l2.boundary.as_text.gsub(')))','))').gsub('MULTIPOLYGON (',', ')
          lb=lb+l2b
          l2.is_active=false
          l2.save
          puts "deleted "+(l2.name||"unnamed")+" "+l2.id.to_s+" as duplicate of "+(l.name||"unnamed")+l.id.to_s
        end
        lb=lb+")"
        l.boundary=lb
        l.save 
      end
    end
  
  end
  true 
end
  
def self.delete_unmatched
  ActiveRecord::Base.connection.execute("delete from lakes where is_active is not true;")
end

def self.add_centroids
  p=Lake.first_by_id
  while p do
    puts p.id
    if p.location==nil then
      location=p.calc_location
      if location then p.location=location; p.save; end
       p.save
    end
    p=Lake.next(p.id)
  end

  true
end

def self.add_codes
  ps=Lake.where(is_active: true).order(:name)
  rec=1
  ps.each do |p|
   p.code='ZLL/'+rec.to_s.rjust(4,'0')
   rec+=1
   p.save
     puts p.code
  end 
true
end

def calc_location
   location=nil
   if self.id then
        locations=Lake.find_by_sql [ 'select id, CASE
                  WHEN (ST_ContainsProperly(boundary, ST_Centroid(boundary)))
                  THEN ST_Centroid(boundary)
                  ELSE ST_PointOnSurface(boundary)
                END AS location from lakes where id='+self.id.to_s ]
        if locations and locations.count>0 then location=locations.first.location else location=nil end
     end
   location
end


def self.first_by_id
  a=Lake.where("id > ? and is_active=true",0).order(:id).first
end


def self.next(id)
  a=Lake.where("id > ? and is_active=true",id).order(:id).first
end

end

