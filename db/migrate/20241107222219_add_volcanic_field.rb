class AddVolcanicField < ActiveRecord::Migration[5.0]
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
      t.point :location,   :srid=>4326, :spatial => true
      t.multi_polygon :boundary,     :srid=>4326, :spatial => true
    end
  end
end
