class AddDescriptionToVkassets < ActiveRecord::Migration
  def change
    add_column :vk_assets, :description, :text
  end
end
