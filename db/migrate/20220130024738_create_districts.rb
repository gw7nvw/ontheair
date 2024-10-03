# typed: false
class CreateDistricts < ActiveRecord::Migration
  def change
    create_table :districts do |t|
      t.spatial :boundary,     limit: {:srid=>4326, :type=>"multi_polygon"}
      t.string :district_code
      t.string :region_code
      t.string :name

      t.timestamps
    end
  end
end
