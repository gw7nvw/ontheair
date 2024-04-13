class Hump < ActiveRecord::Base
require 'csv'

def self.import(filename)
  h=[]
  CSV.foreach(filename, :headers => true) do |row|
    place=row.to_hash
      newplace={}; place.each do |key,value| key = key.gsub(/[^0-9a-z _]/i, ''); newplace[key]=value  end
      p=Hump.find_by(code: newplace["Full Ref"])
      if !p then
        p=Hump.new
      end
      puts newplace
      p.name=newplace["Name"]
      p.code=newplace["Full Ref"]
      p.dxcc=newplace["DXCC"]
      p.region=newplace["Region"][1..2]
      p.elevation=newplace["Summit Elevation in metres"]
      p.prominence=newplace["Summit Prominence (metres)"]
      p.location="POINT(#{newplace["Longitude     E W"]} #{newplace["Latitude         N S"]})"
      puts "POINT(#{newplace["Longitude     E W"]} #{newplace["Latitude         N S"]})"
      p.save
      puts p.name
      puts p.id
      puts p.location
    end
  end
end
