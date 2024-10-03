# typed: false
class CreateLegalRoads < ActiveRecord::Migration
  def change
    create_table :legal_roads do |t|
      t.spatial :boundary,     limit: {:srid=>4326, :type=>"multi_polygon"}

      t.timestamps
    end
  end
end
