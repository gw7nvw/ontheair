class CreatePotaParks < ActiveRecord::Migration
  def change
    create_table :pota_parks do |t|
      t.string :reference
      t.string :name
      t.integer :points
      t.point :location, :spatial => true, :srid => 4326

      t.integer :park_id
      t.integer :island_id

      t.timestamps
    end
  end
end
