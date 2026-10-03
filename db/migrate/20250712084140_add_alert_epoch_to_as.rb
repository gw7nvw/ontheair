class AddAlertEpochToAs < ActiveRecord::Migration[5.0]
  def change
    add_column :admin_settings, :sota_alert_epoch, :string
  end
end
