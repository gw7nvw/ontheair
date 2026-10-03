class CreateAdminTasks < ActiveRecord::Migration[8.0]
  def change
    create_table :admin_tasks do |t|
      t.string :task_type
      t.string :affected_id
      t.string :affected_table
      t.string :affected_url
      t.string :action_url
      t.text :description
      t.boolean :pending, :default => true
      t.timestamps
    end
  end
end
