class CreateSentNotifictions < ActiveRecord::Migration[8.0]
  def change
    create_table :sent_notifications, id: false do |t| # No primary key needed
      t.integer :user_id, null: false
      t.integer :consolidated_spot_id, null: false
      t.datetime :created_at, null: false, default: -> { 'NOW()' }
    end

    # Enforce uniqueness and optimize lookup speed
    add_index :sent_notifications, [:consolidated_spot_id, :user_id], unique: true

    # Optimize cleanup query speed
    add_index :sent_notifications, :created_at
  end
end
