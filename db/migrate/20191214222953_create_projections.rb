# typed: false
class CreateProjections < ActiveRecord::Migration
  def change
    create_table :projections do |t|
       t.string :name
       t.string :proj4
       t.string :wkt
       t.integer :epsg

       t.integer  :createdBy_id
       t.timestamps
    end
  end
end
