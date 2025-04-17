class AddTitleToAdminSettings < ActiveRecord::Migration
  def change
    add_column :admin_settings, :title, :text
    add_column :admin_settings, :name, :text
    add_column :admin_settings, :imagepath, :text
  end

end
