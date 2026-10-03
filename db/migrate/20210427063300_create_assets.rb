# typed: false
class CreateAssets < ActiveRecord::Migration[5.0]
  def change
    create_table :assets do |t|
      t.string :asset_type
      t.string :code
      t.string :url
      t.string :name
      t.boolean :is_active
      t.multi_polygon :boundary, :srid=>4326, :spatial=>true
      t.point :location,:srid=>4326, :spatial=>true
   
      t.timestamps
    end
    add_index "assets", ["asset_type"]
    add_index "assets", ["code"]
  end
end
