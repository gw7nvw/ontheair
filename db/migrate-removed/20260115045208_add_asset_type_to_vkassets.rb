class AddAssetTypeToVkassets < ActiveRecord::Migration[5.0]
  def change
    add_column :vk_assets, :asset_type, :string
  end
end
