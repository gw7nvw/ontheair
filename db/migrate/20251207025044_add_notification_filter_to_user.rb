class AddNotificationFilterToUser < ActiveRecord::Migration
  def change
    add_column :users, :push_external_filter, :string
    add_column :users, :push_include_external, :boolean
  end
end
