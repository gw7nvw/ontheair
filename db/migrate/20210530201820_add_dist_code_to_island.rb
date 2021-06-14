class AddDistCodeToIsland < ActiveRecord::Migration
  def change
     add_column :islands, :dist_code, :string
  end
end
