# typed: false
class RenameParentChild < ActiveRecord::Migration
  def change     
     rename_column :asset_links, :parent_code, :contained_code
     rename_column :asset_links, :child_code, :containing_code

  end
end
