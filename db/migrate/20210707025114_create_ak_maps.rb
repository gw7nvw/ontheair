# typed: false
class CreateAkMaps < ActiveRecord::Migration
  def change
    create_table :ak_maps do |t|
        t.spatial "WKT", limit: {:srid=>4326, :type=>"multi_polygon"}
        t.spatial "location", limit: {:srid=>4326, :type=>"point"}
        t.string "name"
        t.string "code"
    end
  end
end
