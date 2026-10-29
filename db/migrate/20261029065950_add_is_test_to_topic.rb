class AddIsTestToTopic < ActiveRecord::Migration[8.0]
  def change
    add_column :topics, :is_test, :boolean
  end
end
