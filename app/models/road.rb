class Road < ActiveRecord::Base
require 'csv'


def self.import(filename)
  Road.destroy_all
  h=[]
  CSV.foreach(filename, :headers => true) do |row|
    place=row.to_hash
    wkt=place.first[1]
    puts place['t50_fid'], place['name'], wkt.length
    if place  and wkt then
      ActiveRecord::Base.connection.execute("insert into roads (id, name, linestring) values ('"+place['t50_fid']+"','"+(place['name']||"").gsub("'","")+"',ST_Multi(ST_GeomFromText('"+wkt+"',4326)));")
    end

  end; true
end

def self.add_distance_to_assets
   # Points:
   # Find nearest road (in degrees - may not really be nearest due to X/Y having
   # different degrees per meter)
   startid=Asset.find_by_sql [ " select min(id) as id from assets " ]
   endid=Asset.find_by_sql [ " select max(id) as id from assets " ]
   puts startid.first.id.to_s+" to "+endid.first.id.to_s

   puts "Point assets - all in one operation"
   ActiveRecord::Base.connection.execute("UPDATE assets a set nearest_road_id = (select r.id from roads r ORDER BY ST_Distance(a.location, r.linestring) LIMIT 1)  where a.boundary is null and a.nearest_road_id is null;")
     # Calculate distance from nearest road in meters
   ActiveRecord::Base.connection.execute("UPDATE assets a set road_distance = (SELECT ST_Distance(ST_Transform(a.location, 2193), ST_Transform(r.linestring,2193)) from roads r where r.id=a.nearest_road_id) where a.boundary is null and road_distance is null and ST_Y(a.location)>-90;")

   puts "Polygon assets - one at a time"
   ids=Asset.find_by_sql [ " select id, code from assets where boundary is not null and nearest_road_id is null order by id asc" ]

  ids.each do |id|
     puts id.id.to_s+": "+id.code
     # Polygons:
     # Find nearest road (in degrees - may not really be nearest due to X/Y having
     # different degrees per meter)
     tol=0.01
     a=nil
     while tol<2 and a==nil do
       puts "Looking: "+tol.to_s
       ActiveRecord::Base.connection.execute("UPDATE assets a set nearest_road_id = (select r.id from roads r where ST_DWithin(ST_Centroid(r.linestring), a.boundary_simplified, #{tol}) ORDER BY ST_Distance(a.boundary_simplified, r.linestring) LIMIT 1)  where a.boundary is not null and a.id=#{id.id.to_s};")
       tol=tol*10
       a=Asset.find(id).nearest_road_id
     end
     if a==nil then
       puts "looking everywhere"
       ActiveRecord::Base.connection.execute("UPDATE assets a set nearest_road_id = (select r.id from roads r ORDER BY ST_Distance(a.boundary_simplified, r.linestring) LIMIT 1)  where a.boundary is not null and a.id=#{id.id.to_s};")
     end
     puts "."
   end
   ids=Asset.find_by_sql [ " select id, code from assets where boundary is not null and road_distance is null order by id asc" ]
   ids.each do |id|
     puts id.id.to_s+": "+id.code
     # Calculate distance from nearest road in meters
     ActiveRecord::Base.connection.execute("UPDATE assets a set road_distance = (SELECT ST_Distance(ST_Transform(a.boundary, 2193), ST_Transform(r.linestring,2193)) from roads r where r.id=a.nearest_road_id) where a.boundary is not null and a.id=#{id.id.to_s};")
   end

end 
end

