# typed: false
class AddMnzIdToLighthouse < ActiveRecord::Migration[5.0]
  def change
    add_column :lighthouses, :mnz_id, :integer

  end
end
