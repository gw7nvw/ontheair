class AddNotificationFilterToUser < ActiveRecord::Migration[5.0]
  def change
    add_column :users, :push_external_filter, :string
    add_column :users, :push_include_external, :boolean
  end
end
