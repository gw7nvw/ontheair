class AddDisplayFieldsToAssetType < ActiveRecord::Migration
  def change
    add_column :asset_types, :fields, :string
  end
end
