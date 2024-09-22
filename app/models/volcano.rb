class Volcano < ActiveRecord::Base
require 'csv'


def self.import(filename)
  h=[]
  CSV.foreach(filename, :headers => true) do |row|
    place=row.to_hash
      newplace={}; place.each do |key,value| key = key.gsub(/[^0-9a-z _]/i, ''); newplace[key]=value  end
      p=Volcano.find_by(code: newplace["code"])
      if !p then
        p=Volcano.new
      end
      puts newplace
      p.code=newplace["code"]
      p.name=newplace["name"]
      p.age=newplace["age"]
      p.height=newplace["height"]
      p.lat=newplace["lat"]
      p.long=newplace["long"]
      p.az_radius=newplace["az_radius"]
      p.url=newplace["url"]
      p.location="POINT(#{p.long} #{p.lat})"
      p.save
      puts p.name
      puts p.id
    end
  end
end

