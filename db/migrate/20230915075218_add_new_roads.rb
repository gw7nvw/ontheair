# typed: false
class AddNewRoads < ActiveRecord::Migration[5.0]
  def change
    create_table :roads do |t|
      t.line_string :linestring,     :srid=>4326, :spatial => true
      t.string :name

      t.timestamps
    end

  end
end
