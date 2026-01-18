class AddBoundaryToVkAsset < ActiveRecord::Migration
  def change
    add_column :vk_assets, :boundary, :spatial, limit: {:srid=>4326, :type=>"multi_polygon"}
    add_column :vk_assets, :boundary_quite_simplified, :spatial, limit: {:srid=>4326, :type=>"multi_polygon"}
    add_column :vk_assets, :boundary_simplified, :spatial, limit: {:srid=>4326, :type=>"multi_polygon"}
    add_column :vk_assets, :boundary_very_simplified, :spatial, limit: {:srid=>4326, :type=>"multi_polygon"}
    add_column :vk_assets, :caped_id, :integer
  end
end
