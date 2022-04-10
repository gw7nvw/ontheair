class AddDistanceToAssets < ActiveRecord::Migration
  def change
    add_column :assets, :nearest_road_id, :integer
    add_column :assets, :road_distance, :integer
  end
end
