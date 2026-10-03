class AddObjectIdToVkAssets < ActiveRecord::Migration[5.0]
  def change
    add_column :vk_assets, :old_code, :string
  end
end
