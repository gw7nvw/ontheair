class CreateRoads < ActiveRecord::Migration
  def change
    create_table :roads do |t|
      t.spatial :linestring,     limit: {:srid=>4326, :type=>"linestring"}
      t.string :hway_num
      t.integer :lane_count
      t.string :surface

      t.timestamps
    end
  end
end
