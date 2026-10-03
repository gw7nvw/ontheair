# typed: false
class AddCodeToIsland < ActiveRecord::Migration[5.0]
  def change
    add_column :islands, :code, :string

  end
end
