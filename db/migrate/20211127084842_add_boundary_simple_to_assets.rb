class AddBoundarySimpleToAssets < ActiveRecord::Migration
  def change
      add_column :assets, :boundary_quite_simplified, :multi_polygon,    srid: 4326
      add_column :assets, :boundary_simplified, :multi_polygon,    srid: 4326
      add_column :assets, :boundary_very_simplified, :multi_polygon,    srid: 4326
  end
end
