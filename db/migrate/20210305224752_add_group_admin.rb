class AddGroupAdmin < ActiveRecord::Migration
  def change
   add_column :users, :group_admin, :boolean


  end
end
