# typed: false
class AddPnpClassToAssetType < ActiveRecord::Migration
  def change
     add_column :asset_types, :pnp_class, :string
  end
end
