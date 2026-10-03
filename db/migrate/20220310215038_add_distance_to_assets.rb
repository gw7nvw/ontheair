# typed: false
class AddDistanceToAssets < ActiveRecord::Migration[5.0]
  def change
    add_column :assets, :nearest_road_id, :integer
    add_column :assets, :road_distance, :integer
  end
end
