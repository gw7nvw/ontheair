# typed: false
class AddSimpleBoundaryToDistricts < ActiveRecord::Migration
  def change
      add_column :districts, :boundary_quite_simplified, :multi_polygon,    srid: 4326
      add_column :districts, :boundary_simplified, :multi_polygon,    srid: 4326
      add_column :districts, :boundary_very_simplified, :multi_polygon,    srid: 4326
      add_column :regions, :boundary_quite_simplified, :multi_polygon,    srid: 4326
      add_column :regions, :boundary_simplified, :multi_polygon,    srid: 4326
      add_column :regions, :boundary_very_simplified, :multi_polygon,    srid: 4326
  end
end
