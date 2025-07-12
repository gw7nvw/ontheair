class AddAlertEpochToAs < ActiveRecord::Migration
  def change
    add_column :admin_settings, :sota_alert_epoch, :string
  end
end
