class AddObjectIdToVkAssets < ActiveRecord::Migration
  def change
    add_column :vk_assets, :old_code, :string
  end
end
