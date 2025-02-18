class AddWithinSightToAssetType < ActiveRecord::Migration
  def change
    add_column :asset_types, :use_within_sight, :boolean
  end
end
