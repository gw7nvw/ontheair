class AddDisplayNameToAssets < ActiveRecord::Migration
  def change
    add_column :asset_types, :display_name, :string
  end
end
