# typed: false
class CreateRegions < ActiveRecord::Migration[5.0]
  def change
    create_table :regions do |t|
      t.multi_polygon :boundary,     :srid=>4326, :spatial => true
      t.string :regc_code
      t.string :sota_code
      t.string :name
      
      t.timestamps
    end
  end
end
