class CreateStates < ActiveRecord::Migration
  def change
    create_table :states do |t|
      t.string   "code"
      t.string   "pnp_code"
      t.string   "name"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.spatial  "boundary",                  limit: {:srid=>4326, :type=>"multi_polygon"}
      t.spatial  "boundary_quite_simplified", limit: {:srid=>4326, :type=>"multi_polygon"}
      t.spatial  "boundary_simplified",       limit: {:srid=>4326, :type=>"multi_polygon"}
      t.spatial  "boundary_very_simplified",  limit: {:srid=>4326, :type=>"multi_polygon"}
      t.string   "dxcc"
      t.timestamps
    end
    add_column :regions, :state_code, :string
    add_column :districts, :state_code, :string
    add_column :assets, :state, :string
  end
end
