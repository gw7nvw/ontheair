class AddCodeToIsland < ActiveRecord::Migration
  def change
    add_column :islands, :code, :string

  end
end
