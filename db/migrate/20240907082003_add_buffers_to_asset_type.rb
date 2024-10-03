# typed: false
class AddBuffersToAssetType < ActiveRecord::Migration
  def change
    add_column :asset_types, :ele_buffer, :integer
    add_column :asset_types, :dist_buffer, :integer
  end
end
