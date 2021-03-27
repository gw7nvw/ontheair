class Docparks < ActiveRecord::Base
require 'csv'

# To load new doc parks layer
# add 'id column tio eaxch row
# # change row titrles to id, Overlays: nil, NaPALIS_ID: nil, End_Date: nil, Vested: nil, Section: nil, Classified: nil, Legislatio: nil, Recorded_A: nil, Conservati: nil, Control_Ma: nil, Government: nil, Private_Ow: nil, Local_Purp: nil, Type: nil, Start_Date: nil, Name: nil, WKT: nil

# in psql delete old database: delete from docparks;
# rails c production
# DocPark.my_import(filename.csv)
# Park.update_table

    establish_connection "docparks"


def self.my_import(file)

  CSV.foreach(file, :headers => true) do |row|
    h=row.to_hash
    h.shift
    self.create!(h)
end
end
end
