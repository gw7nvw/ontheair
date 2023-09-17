class DocTrack < ActiveRecord::Base
require 'csv'


def self.import(filename)
  DocTrack.destroy_all
  h=[]
  CSV.foreach(filename, :headers => true) do |row|
    place=row.to_hash
    wkt=place.first[1]
    puts place['DESCRIPTION'], place['OBJECT_TYPE_DESCRIPTION'], wkt.length
    if place  and wkt then
      ActiveRecord::Base.connection.execute("insert into doc_tracks (name, object_type, linestring) values ('"+place['DESCRIPTION'].gsub("'","")+"','"+place['OBJECT_TYPE_DESCRIPTION']+"',ST_Multi(ST_GeomFromText('"+wkt+"',4326)));")
    end

  end; true
end

end
