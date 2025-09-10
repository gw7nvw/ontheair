class AddPushToUser < ActiveRecord::Migration
  def change
    add_column :users, :push_app_token, :string
    add_column :users, :push_user_token, :string

  end
end
