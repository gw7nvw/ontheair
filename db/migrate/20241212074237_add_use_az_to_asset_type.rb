class AddUseAzToAssetType < ActiveRecord::Migration
  def change
    add_column :asset_types, :use_az, :boolean
  end
end
