class Lighthouse < ActiveRecord::Base
require 'csv'

def self.import(filename)
  h=[]
  CSV.foreach(filename, :headers => true) do |row|
    place=row.to_hash
    if !['Unofficial Replaced','Unofficial Discontinued'].include?(row['status']) then
      newplace={}; place.each do |key,value| key = key.gsub(/[^0-9a-z _]/i, ''); newplace[key]=value  end
      p=Lighthouse.find_by(t50_fid: newplace["t50_fid"])
      if !p then 
        p=Lighthouse.new 
      end
      puts newplace
      p.name=newplace["name"]
      p.t50_fid=newplace["t50_fid"]
      p.loc_type=newplace["location"]
      p.status=newplace["status"]
      p.str_type=newplace["type"]
      p.location=newplace["WKT"]
      p.save
      puts p.name
      puts p.id
    end
  end
end

def self.add_regions
     count=0
     lighthouses=Lighthouse.all
     lighthouses.each do |a|
       puts a.name
       if a.region==nil or a.region=="" then
         count+=1
         a.add_region
         if a.region==nil then puts a.code+" "+count.to_s+" "+(a.region||"null")+" "+a.name+" "+a.WKT.as_text end
       end
     end
end

def add_region
      if self.location then region=Region.find_by_sql [ %q{ SELECT * 
       FROM regions dp
       WHERE ST_DWithin(ST_GeomFromText('}+self.location.as_text+%q{', 4326), boundary, 100000, false) 
       ORDER BY ST_Distance(ST_GeomFromText('}+self.location.as_text+%q{', 4326), boundary) LIMIT 50; } ]
      else puts "ERROR: place without location. Name: "+self.name+", id: "+self.id.to_s end

    if region and region.count>0 then #and self.region != region.first.sota_code then
      self.region=region.first.sota_code
      self.save
    end
end

  def self.add_dist_codes
     lighthouses=Lighthouse.find_by_sql [ " select * from lighthouses where code='' or code is null and name is not null order by name" ]
     lighthouses.each do |p|
       code=self.get_next_dist_code(p.region)
       p.code=code
       p.save
       puts code +" - "+(p.name||"")
     end
  end

  def self.get_next_dist_code(region)
    if !region or region=='' then region='ZZ' end
    last_codes=Lighthouse.find_by_sql [ " select code from lighthouses where code like 'ZLB/%%' and code is not null order by code desc limit 1;" ]
    if last_codes and last_codes.count>0 and last_codes.first.code then
      last_code=last_codes.first.code
    else
      last_code='ZLB/000'
    end
    next_code=last_code[0..3]+(((last_code[4..6].to_i)+1).to_s.rjust(3,'0'))
    next_code
  end

end

