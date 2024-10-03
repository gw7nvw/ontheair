# typed: false
class AddCodeToParks < ActiveRecord::Migration
  def change
    add_column :parks, :code, :string
  end
end
