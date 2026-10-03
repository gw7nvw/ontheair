class AddAccessTypeToUserAgents < ActiveRecord::Migration[5.0]
  def change
    add_column :user_agents, :html_count, :integer, default: 0, null: false
    add_column :user_agents, :js_count,   :integer, default: 0, null: false
    add_column :user_agents, :confirmed_human,   :boolean
  end
end
