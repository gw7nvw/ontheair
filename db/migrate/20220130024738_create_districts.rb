# typed: false
class CreateDistricts < ActiveRecord::Migration[5.0]
  def change
    create_table :districts do |t|
      t.multi_polygon :boundary,     :srid=>4326, :spatial => true
      t.string :district_code
      t.string :region_code
      t.string :name

      t.timestamps
    end
  end
end
