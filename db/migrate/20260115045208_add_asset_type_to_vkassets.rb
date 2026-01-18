class AddAssetTypeToVkassets < ActiveRecord::Migration
  def change
    add_column :vk_assets, :asset_type, :string
  end
end
