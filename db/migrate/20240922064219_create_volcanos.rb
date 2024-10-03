# typed: false
class CreateVolcanos < ActiveRecord::Migration
  def change
    create_table :volcanos do |t|
      t.string :code
      t.string :name
      t.string :status
      t.string :field_name
      t.integer :age
      t.string :period
      t.string :epoch
      t.integer :height
      t.float :lat
      t.float :long
      t.float :az_radius
      t.string :url
      t.string :description
      t.spatial  "location",   limit: {:srid=>4326, :type=>"point"}

    end
  end
end
