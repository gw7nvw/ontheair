class AddPushActiveToUser < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :push_active, :boolean
  end
end
