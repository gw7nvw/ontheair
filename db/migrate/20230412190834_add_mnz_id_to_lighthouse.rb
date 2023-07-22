class AddMnzIdToLighthouse < ActiveRecord::Migration
  def change
    add_column :lighthouses, :mnz_id, :integer

  end
end
