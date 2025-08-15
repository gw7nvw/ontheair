class AddWebAdminToUser < ActiveRecord::Migration
  def change
    add_column :users, :is_web_admin, :boolean
  end
end
