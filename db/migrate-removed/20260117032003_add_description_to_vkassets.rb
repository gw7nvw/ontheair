class AddDescriptionToVkassets < ActiveRecord::Migration[5.0]
  def change
    add_column :vk_assets, :description, :text
  end
end
