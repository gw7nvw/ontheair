class Crownparks < ActiveRecord::Base
require 'csv'

# To load new doc parks layer
# add 'id column tio eaxch row
# change POLYGON (( to MULTIPOLYGON ((( and ))" to )))"
# # change row titrles to id, Overlays: nil, NaPALIS_ID: nil, End_Date: nil, Vested: nil, Section: nil, Classified: nil, Legislatio: nil, Recorded_A: nil, Conservati: nil, Control_Ma: nil, Government: nil, Private_Ow: nil, Local_Purp: nil, Type: nil, Start_Date: nil, Name: nil, WKT: nil

# in psql delete old database: delete from docparks;
# rails c production
# Crownparks.my_import(filename.csv)
# update crownparks set ctrl_mg_vst=NULL where ctrl_mg_vst='NULL'
# Park.update_table

    establish_connection "crownparks"

def self.ecan_import(file)
  h=[]
  CSV.foreach(file, :headers => true) do |row|
    h.push(row.to_hash)
  end
 
  h.each do |park|
  p=Crownparks.new
  p.name=park["COMMON_NAM"]
  p.WKT=park["WKT"]
  p.reserve_type="Regional park"
  p.start_date=park["DATE_CREAT"]
  p.recorded_area=park["Shape_Area"].to_d/10000
  p.save
  puts "Added crownpark :"+p.id.to_s+" - "+p.name
  end
end

def self.my_import(file)
  count=0
  CSV.foreach(file, :headers => true) do |row|
    h=row.to_hash
    h.shift
    self.create!(h)
    puts count
    count+=1
end
end
end
