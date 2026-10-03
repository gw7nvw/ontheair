# typed: false
class AddLastSotaUpdateToAdminSettings < ActiveRecord::Migration[5.0]
  def change
    add_column :admin_settings, :last_sota_activation_update_at, :datetime
    add_column :admin_settings, :last_sota_update_at, :datetime
    add_column :admin_settings, :last_pota_update_at, :datetime
    add_column :admin_settings, :last_wwff_update_at, :datetime

  end
end
