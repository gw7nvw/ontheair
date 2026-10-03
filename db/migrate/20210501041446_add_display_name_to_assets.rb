# typed: false
class AddDisplayNameToAssets < ActiveRecord::Migration[5.0]
  def change
    add_column :asset_types, :display_name, :string
  end
end
