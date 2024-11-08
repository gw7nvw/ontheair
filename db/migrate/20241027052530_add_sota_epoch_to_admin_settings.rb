class AddSotaEpochToAdminSettings < ActiveRecord::Migration
  def change
    add_column :admin_settings, :sota_epoch, :string
    add_column :external_spots, :epoch, :string
    add_column :external_spots, :is_test, :boolean
    add_column :external_spots, :points, :string
    add_column :external_spots, :altM, :string
    add_column :asset_types, :is_zlota, :boolean
  end
end
