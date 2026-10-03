# typed: false
class AddOwnerToParks < ActiveRecord::Migration[5.0]
  def change
   add_column :parks, :owner, :string
    
  end
end
