class AddNotificationTypeToSentNotifications < ActiveRecord::Migration[8.0]
  def change
    # Default to 0 (or whatever your NOTIFICATION_PUSHOVER integer value is) so existing rows don't fail NOT NULL
    add_column :sent_notifications, :notification_type, :integer, null: false, default: 1

    # Remove the old 2-column unique index
    remove_index :sent_notifications,
                 name: "index_sent_notifications_on_consolidated_spot_id_and_user_id",
                 column: [:consolidated_spot_id, :user_id],
                 unique: true

    # Add the new 3-column unique index
    add_index :sent_notifications,
              [:consolidated_spot_id, :user_id, :notification_type],
              unique: true,
              name: "idx_sent_notifications_spot_user_type"
  end
end
