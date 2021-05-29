class AddIndexToAssetlink < ActiveRecord::Migration
  def self.up
    add_index :asset_links, :parent_code
    add_index :asset_links, :child_code
  end

  def self.down
    remove_index :asset_links, :parent_code
    remove_index :asset_links, :child_code
  end
end
