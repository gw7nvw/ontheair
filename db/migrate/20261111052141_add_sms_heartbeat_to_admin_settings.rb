class AddSmsHeartbeatToAdminSettings < ActiveRecord::Migration[8.0]
  def change
    add_column :admin_settings, :sms_heartbeat, :datetime
  end
end
