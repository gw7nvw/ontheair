# typed: false
class CreateRoads < ActiveRecord::Migration[5.0]
  def change
    create_table :roads do |t|
      t.line_string :linestring,     :srid=>4326, :spatial => true
      t.string :hway_num
      t.integer :lane_count
      t.string :surface

      t.timestamps
    end
  end
end
