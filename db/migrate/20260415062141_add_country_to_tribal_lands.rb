class AddCountryToTribalLands < ActiveRecord::Migration[5.0]
  create_table "nz_tribal_lands", primary_key: "ogc_fid", force: true do |t|
    t.multi_polygon :wkb_geometry, :srid=>4326#, :spatial => true
    t.decimal :id, :precision => 10, :scale => 0
    t.string  :name,  :limit => 80
    t.string  :country
    t.multi_polygon :boundary_quite_simplified, :srid=>4326#, :spatial => true
    t.multi_polygon :boundary_simplified,       :srid=>4326#, :spatial => true
    t.multi_polygon :boundary_very_simplified,  :srid=>4326#, :spatial => true
  end

end
