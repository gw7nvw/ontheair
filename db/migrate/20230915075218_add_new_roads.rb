class AddNewRoads < ActiveRecord::Migration
  def change
    create_table :roads do |t|
      t.spatial :linestring,     limit: {:srid=>4326, :type=>"multi_linestring"}
      t.string :name

      t.timestamps
    end

  end
end
