class AddFlagToUsers < ActiveRecord::Migration
  def change
    add_column :users, :outstanding, :boolean
  end
   
end
