class Nzgdb < ActiveRecord::Base
require 'csv'

    establish_connection "nzgdb"

def self.import(filename)
  h=[]
  CSV.foreach(filename, :headers => true) do |row|
    place=row.to_hash
    if !['Unofficial Replaced','Unofficial Discontinued'].include?(row['status']) then
      newplace={}; place.each do |key,value| key = key.gsub(/[^0-9a-z _]/i, ''); newplace[key]=value  end
      p=Nzgdb.new(newplace)
      p.save
      puts p.id
    end
  end
end

def self.first_by_id
  a=Nzgdb.where("id > ?",0).order(:id).first
end


def self.next(id)
  a=Nzgdb.where("id > ?",id).order(:id).first
end

end

