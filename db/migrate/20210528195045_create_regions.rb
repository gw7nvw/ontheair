class CreateRegions < ActiveRecord::Migration
  def change
    create_table :regions do |t|
      t.spatial :boundary,     limit: {:srid=>4326, :type=>"multi_polygon"}
      t.string :regc_code
      t.string :sota_code
      t.string :name
      
      t.timestamps
    end
  end
end
