# typed: false
class CreateAssets < ActiveRecord::Migration
  def change
    create_table :assets do |t|
      t.string :asset_type
      t.string :code
      t.string :url
      t.string :name
      t.boolean :is_active
      t.spatial :boundary,     limit: {:srid=>4326, :type=>"multi_polygon"}
      t.spatial :location,     limit: {:srid=>4326, :type=>"point"}
   
      t.timestamps
    end
    add_index "assets", ["asset_type"]
    add_index "assets", ["code"]
  end
end
