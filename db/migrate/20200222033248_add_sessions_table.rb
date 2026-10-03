# typed: false
class AddSessionsTable < ActiveRecord::Migration[5.0]
  def change
    add_index :sessions, :session_id, :unique => true
    add_index :sessions, :updated_at
  end
end
