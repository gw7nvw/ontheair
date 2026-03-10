class AddSchedsToAdminStettings < ActiveRecord::Migration
  def change
    add_column :admin_settings, :last_minute_sched_at, :datetime
    add_column :admin_settings, :last_monthly_sched_at, :datetime
    add_column :admin_settings, :last_sota_update_id, :string
    add_column :admin_settings, :last_pota_update_id, :string

  end
end
