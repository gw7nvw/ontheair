class AddLayerProjToAdminSettings < ActiveRecord::Migration[5.0]
  def change
    add_column :admin_settings, :default_projection, :text
    add_column :admin_settings, :default_layer, :text
    add_column :admin_settings, :default_x, :text
    add_column :admin_settings, :default_y, :text
  end
end
