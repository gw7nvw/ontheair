class AddNotificationToUserTopicLink < ActiveRecord::Migration[5.0]
  def change
    add_column :user_topic_links, :notification, :boolean
  end
end
