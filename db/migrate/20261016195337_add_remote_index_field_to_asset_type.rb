class AddRemoteIndexFieldToAssetType < ActiveRecord::Migration[8.0]
  def change
    add_column :asset_types, :remote_index_field, :string
  end
end
