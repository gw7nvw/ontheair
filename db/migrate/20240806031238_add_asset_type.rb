# typed: false
class AddAssetType < ActiveRecord::Migration
  def change
    add_column :sota_activations, :asset_type, :string
    add_column :sota_chases, :asset_type, :string
  end
end
