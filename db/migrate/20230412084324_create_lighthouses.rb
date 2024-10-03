# typed: false
class CreateLighthouses < ActiveRecord::Migration
  def change
    create_table :lighthouses do |t|
      t.string :t50_fid
      t.string :loc_type
      t.string :status
      t.string :str_type
      t.string :name
      t.point :location, :spatial => true, :srid => 4326
      t.string :code
      t.string :region
      t.timestamps
    end
  end
end
