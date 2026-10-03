# typed: false
class CreateAkMaps < ActiveRecord::Migration[5.0]
  def change
    create_table :ak_maps do |t|
        t.multi_polygon "WKT", :srid=>4326, :spatial => true
        t.point "location", :srid=>4326, :spatial => true
        t.string "name"
        t.string "code"
    end
  end
end
