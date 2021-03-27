class CreateSotaPeaks < ActiveRecord::Migration
  def change
    create_table :sota_peaks do |t|
      t.string :summit_code
      t.string :name
      t.string :short_code
      t.string :alt
      t.point :location,  :spatial => true, :srid => 4326
      t.integer :points
      t.integer :park_id
      t.integer :island_id

      t.timestamps
    end
  end
end
