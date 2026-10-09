class AbstractGisDataAccess < ActiveRecord::Migration[8.0]
  def change
    add_column :assets, :geom_id, :string
    add_column :assets, :geom_source, :string
    add_column :assets, :name_id, :string
    add_column :assets, :name_source, :string
    add_column :data_sources, :mdl_name, :string
  end
end
