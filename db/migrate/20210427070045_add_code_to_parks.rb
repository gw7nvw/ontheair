# typed: false
class AddCodeToParks < ActiveRecord::Migration[5.0]
  def change
    add_column :parks, :code, :string
  end
end
