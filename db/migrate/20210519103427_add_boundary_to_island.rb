# typed: false
class AddBoundaryToIsland < ActiveRecord::Migration[5.0]
  def change
      add_column :islands, :boundary, :multi_polygon,    srid: 4326
  end
end
