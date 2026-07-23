class AddSimpleBoundariesToTribalLands < ActiveRecord::Migration
  def change
      add_column :nz_tribal_lands, :boundary_quite_simplified, :multi_polygon,    srid: 4326
      add_column :nz_tribal_lands, :boundary_simplified, :multi_polygon,    srid: 4326
      add_column :nz_tribal_lands, :boundary_very_simplified, :multi_polygon,    srid: 4326
  end
end
