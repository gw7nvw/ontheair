class AddPushoverConfigOptions < ActiveRecord::Migration
  def change    
    add_column :users, :push_include_comments, :boolean
    add_column :users, :push_include_map, :boolean
  end
end
