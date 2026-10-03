# typed: false
class AddGroupAdmin < ActiveRecord::Migration[5.0]
  def change
   add_column :users, :group_admin, :boolean


  end
end
