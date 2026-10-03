class AddTitleToAdminSettings < ActiveRecord::Migration[5.0]
  def change
    add_column :admin_settings, :title, :text
    add_column :admin_settings, :name, :text
    add_column :admin_settings, :imagepath, :text
  end

end
