class AddNotificationTypeToUserNotificationLinks < ActiveRecord::Migration[8.0]
  def change
    add_column :user_notification_links, :notification_type, :integer
  end
end
