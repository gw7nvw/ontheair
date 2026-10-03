# typed: false
class AddPnpClassToAssetType < ActiveRecord::Migration[5.0]
  def change
     add_column :asset_types, :pnp_class, :string
  end
end
