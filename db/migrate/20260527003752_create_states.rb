class CreateStates < ActiveRecord::Migration[5.0]
  def change
    create_table :states do |t|
      t.string   "code"
      t.string   "pnp_code"
      t.string   "name"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.multi_polygon  "boundary",                  :srid=>4326, :spatial => true 
      t.multi_polygon  "boundary_quite_simplified", :srid=>4326, :spatial => true
      t.multi_polygon  "boundary_simplified",       :srid=>4326, :spatial => true
      t.multi_polygon  "boundary_very_simplified",  :srid=>4326, :spatial => true
      t.string   "dxcc"
      t.timestamps
    end
    add_column :regions, :state_code, :string
    add_column :districts, :state_code, :string
    add_column :assets, :state, :string
  end
end
