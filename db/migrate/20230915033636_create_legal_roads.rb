# typed: false
class CreateLegalRoads < ActiveRecord::Migration[5.0]
  def change
    create_table :legal_roads do |t|
      t.multi_polygon :boundary,     :srid=>4326, :spatial => true

      t.timestamps
    end
  end
end
