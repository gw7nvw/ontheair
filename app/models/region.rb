class Region < ActiveRecord::Base

require 'csv'


def self.import(filename)
  h=[]
  CSV.foreach(filename, :headers => true) do |row|
    place=row.to_hash
    ActiveRecord::Base.connection.execute("insert into regions (regc_code, name, boundary) values ('"+place['REGC_code']+"','"+place['REGC_name'].gsub("'","''")+"',ST_GeomFromText('"+place['WKT']+"',4326));")
  end; true
end

def self.add_sota_codes
names=[["Northland Region","NL"],
 ["Auckland Region","AK"],
 ["Waikato Region","WK"],
 ["Bay of Plenty Region","BP"],
 ["Gisborne Region","GI"],
 ["Hawke's Bay Region","HB"],
 ["Taranaki Region","TN"],
 ["Manawatū-Whanganui Region","MW"],
 ["Wellington Region","WL"],
 ["West Coast Region","WC"],
 ["Canterbury Region","CB"],
 ["Otago Region","OT"],
 ["Southland Region","SL"],
 ["Tasman Region","TM"],
 ["Nelson Region","TM"],
 ["Marlborough Region","MB"],
 ["Area Outside Region","CI"]]

 Region.all.each do |region|
  namelst=names.select{ |n| n[0]==region.name}
  if namelst and namelst.length>0 then 
    name=namelst.first
    puts region.name
    puts name[1]
    ActiveRecord::Base.connection.execute("update regions set sota_code='"+name[1]+"' where id="+region.id.to_s+";")
  end
 end; true
end
def assets
  as=Asset.where(region: self.sota_code)
end


def assets_by_type(type)
  as=Asset.where(region: self.sota_code, asset_type: type)
end

def districts
  districts=District.where(region_code: self.sota_code)
end
end
