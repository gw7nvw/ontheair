class AddNotificationToUserTopicLink < ActiveRecord::Migration
  def change
    add_column :user_topic_links, :notification, :boolean
  end
end
