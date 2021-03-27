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
