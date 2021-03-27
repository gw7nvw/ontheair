class AddSessionsTable < ActiveRecord::Migration
  def change
    add_index :sessions, :session_id, :unique => true
    add_index :sessions, :updated_at
  end
end
