# typed: false
class CreateMaplayers < ActiveRecord::Migration
  def change
    create_table :maplayers do |t|
      t.string :name
      t.string :baseurl
      t.string :basemap
      t.integer :maxzoom
      t.integer :minzoom
      t.string :imagetype


      t.timestamps
    end
  end
end
