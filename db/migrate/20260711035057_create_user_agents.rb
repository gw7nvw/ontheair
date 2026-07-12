class CreateUserAgents < ActiveRecord::Migration
  def change
    create_table :user_agents do |t|
      t.text :user_agent, null: false
      t.integer :access_count, default: 0, null: false
      t.text :user_ip, null: false
      t.boolean :suspected_bot
      t.boolean :confirmed_bot
      t.integer :suspicious_access_count, default: 0, null: false
      t.timestamps null: false
    end

    # Indexing user_agent ensures fast lookups as rows scale
    add_index :user_agents, [:user_ip, :user_agent], unique: true
  end
end
