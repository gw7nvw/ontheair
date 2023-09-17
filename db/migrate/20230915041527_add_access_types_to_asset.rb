class AddAccessTypesToAsset < ActiveRecord::Migration
  def change
    add_column :assets, :access_road_ids, :string, array: true, default: []
    add_column :assets, :access_legal_road_ids, :string, array: true, default: []
    add_column :assets, :access_park_ids, :string, array: true, default: []
    add_column :assets, :access_track_ids, :string, array: true, default: []
    add_column :assets, :public_access, :boolean
  end
end
