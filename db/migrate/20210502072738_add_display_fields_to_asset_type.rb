# typed: false
class AddDisplayFieldsToAssetType < ActiveRecord::Migration[5.0]
  def change
    add_column :asset_types, :fields, :string
  end
end
