class AddVkHeartbeatToAdminSettings < ActiveRecord::Migration[8.0]
  def change
        add_column :admin_settings, :vk_sms_heartbeat, :datetime
  end
end
