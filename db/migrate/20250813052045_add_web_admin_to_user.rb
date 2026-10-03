class AddWebAdminToUser < ActiveRecord::Migration[5.0]
  def change
    add_column :users, :is_web_admin, :boolean
  end
end
