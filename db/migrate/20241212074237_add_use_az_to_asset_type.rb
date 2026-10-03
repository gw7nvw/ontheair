class AddUseAzToAssetType < ActiveRecord::Migration[5.0]
  def change
    add_column :asset_types, :use_az, :boolean
  end
end
