class Lake < ActiveRecord::Base
require 'csv'

    establish_connection "lakes"

def self.import(filename)
  CSV.foreach(filename, :headers => true) do |row|
    h=row.to_hash
    boundary=h.first[1]
    if boundary[0..6]=="POLYGON" then boundary="MULTIPOLYGON ("+boundary[8..-1]+")" end
    l=Lake.create(name: h['name'], topo50_fid: h['t50_fid'], boundary: boundary )
    if l then puts l.id else puts "FAIL" end
  end 
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

def self.delete_unnamed
  ActiveRecord::Base.connection.execute("delete from lakes where name is null;")
end

def self.add_codes
  ps=Lake.all.order(:name)
  rec=1
  ps.each do |p|
   p.code='ZLL/'+rec.to_s.rjust(4,'0')
   rec+=1
   p.save
     puts p.code
  end 
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
  a=Lake.where("id > ?",0).order(:id).first
end


def self.next(id)
  a=Lake.where("id > ?",id).order(:id).first
end

end

