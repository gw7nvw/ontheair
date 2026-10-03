# typed: false
class AddFlagToUsers < ActiveRecord::Migration[5.0]
  def change
    add_column :users, :outstanding, :boolean
  end
   
end
