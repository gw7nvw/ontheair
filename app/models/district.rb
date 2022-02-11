class District < ActiveRecord::Base
require 'csv'


def self.import(filename)
  District.destroy_all
  h=[]
  CSV.foreach(filename, :headers => true) do |row|
    place=row.to_hash
    puts place['TA2021_V1_00'], place['TA2021_V1_00_NAME'], (place['WKT']||"").length
    if place  and place['WKT'] then 
      ActiveRecord::Base.connection.execute("insert into districts (id, name, boundary) values ('"+place['TA2021_V1_00']+"','"+place['TA2021_V1_00_NAME'].gsub("'","''")+"',ST_GeomFromText('"+place['WKT']+"',4326));")
    end

  end; true
end

def self.add_regions
  District.all.each do |district|
    regions=Region.find_by_sql [ " select r.id, r.sota_code from districts d inner join regions r on ST_Within(ST_PointOnSurface(d.boundary), r.boundary) where d.id = "+district.id.to_s ]
    if regions and regions.count>0 then 
      ActiveRecord::Base.connection.execute("update districts set region_code='"+regions.first.sota_code+"' where id="+district.id.to_s+";")
    end
    #hack as Invers fails to match
    if district.name=="Invercargill City" then
      ActiveRecord::Base.connection.execute("update districts set region_code='SL' where id="+district.id.to_s+";")
    end

  end; true
  
end

def self.add_district_codes
  District.all.order(:id).each do |district|
    dc=district.name.split(" ").first[0]+district.name.split(" ").last[0]
    index=0
    free=false
    while free==false do
      index+=1
      dup=District.where(district_code: dc+index.to_s)
      if !dup or dup.count==0 then free=true end
    end 
    dcs=dc+index.to_s
    ActiveRecord::Base.connection.execute("update districts set district_code='"+dcs+"' where id="+district.id.to_s+";")
  end; true
end

def region_name
  name=""
  r=Region.find_by(sota_code: self.region_code)
  if r then name=r.name.gsub('Region','') end
end


def assets
  as=Asset.where(district: self.district_code)
end


def assets_by_type(type)
  as=Asset.where(district: self.district_code, asset_type: type)
end

end
