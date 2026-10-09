class CreateDataSources < ActiveRecord::Migration[8.0]
  def change
    create_table :data_sources do |t|
      t.string :name
      t.string :database_name
      t.string :table_name
      t.datetime :last_update
      t.string :index_column
      t.string :name_column
      t.string :geom_column
      t.boolean :is_zl
      t.boolean :is_vk
      t.timestamps
    end
  end
end
