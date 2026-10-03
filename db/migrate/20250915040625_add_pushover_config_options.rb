class AddPushoverConfigOptions < ActiveRecord::Migration[5.0]
  def change    
    add_column :users, :push_include_comments, :boolean
    add_column :users, :push_include_map, :boolean
  end
end
