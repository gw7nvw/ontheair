class GeologicalEon < ActiveRecord::Base
require 'csv'

def self.import(filename)
  h=[]
  CSV.foreach(filename, :headers => true) do |row|
    place=row.to_hash
      newplace={}; place.each do |key,value| key = key.gsub(/[^0-9a-z _]/i, ''); newplace[key]=value  end
      p=GeologicalEon.new(newplace)
      puts p.to_json
      p.save
      puts p.id
    end
end

def self.from_date(date_mya)
  if date_mya!=nil then
    s=GeologicalEon.find_by("start_mya>=#{date_mya} and end_mya<#{date_mya}")
  end
  if s then s.name else nil end 
end
end
