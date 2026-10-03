# typed: false
class AddBuffersToAssetType < ActiveRecord::Migration[5.0]
  def change
    add_column :asset_types, :ele_buffer, :integer
    add_column :asset_types, :dist_buffer, :integer
  end
end
