# typed: false
class AddDistCodeToIsland < ActiveRecord::Migration[5.0]
  def change
     add_column :islands, :dist_code, :string
  end
end
