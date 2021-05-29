class AddBoundaryToIsland < ActiveRecord::Migration
  def change
      add_column :islands, :boundary, :multi_polygon,    srid: 4326
  end
end
