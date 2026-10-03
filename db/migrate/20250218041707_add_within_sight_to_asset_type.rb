class AddWithinSightToAssetType < ActiveRecord::Migration[5.0]
  def change
    add_column :asset_types, :use_within_sight, :boolean
  end
end
