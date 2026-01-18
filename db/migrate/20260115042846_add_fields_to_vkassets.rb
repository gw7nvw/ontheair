class AddFieldsToVkassets < ActiveRecord::Migration
  def change
    add_column :vk_assets, :area, :float
    add_column :vk_assets, :is_active, :boolean
    add_column :vk_assets, :url, :string
  end
end
