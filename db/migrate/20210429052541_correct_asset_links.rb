# typed: false
class CorrectAssetLinks < ActiveRecord::Migration
  def change
    change_column :asset_links, :parent_id, :string
    change_column :asset_links, :child_id, :string
    rename_column :asset_links, :parent_id, :parent_code
    rename_column :asset_links, :child_id, :child_code
  end
end
