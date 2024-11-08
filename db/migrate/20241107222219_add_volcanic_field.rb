class AddVolcanicField < ActiveRecord::Migration
  def change
    add_column :volcanos, :field_code, :string
    add_column :assets, :field_code, :string
    add_column :asset_types, :use_volcanic_field, :boolean
    create_table :volcanic_fields do |t|
      t.string :code
      t.string :name
      t.string :period
      t.string :epoch
      t.string :eon
      t.string :era
      t.float :min_age
      t.float :max_age
      t.string :description
      t.spatial :location,   limit: {:srid=>4326, :type=>"point"}
      t.spatial :boundary,     limit: {:srid=>4326, :type=>"multi_polygon"}
    end
  end
end
