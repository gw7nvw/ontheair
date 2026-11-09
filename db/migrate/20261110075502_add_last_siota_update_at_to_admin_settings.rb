class AddLastSiotaUpdateAtToAdminSettings < ActiveRecord::Migration[8.0]
  def change
    add_column :admin_settings, :last_siota_update_id, :string
    add_column :admin_settings, :last_siota_update_at, :datetime
  end
end
