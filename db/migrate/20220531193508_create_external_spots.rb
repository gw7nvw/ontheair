class CreateExternalSpots < ActiveRecord::Migration
  def change
    create_table :external_spots do |t|
      t.datetime :time
      t.string :callsign
      t.string :activatorCallsign
      t.string :code
      t.string :name
      t.string :frequency
      t.string :mode
      t.string :comments
      t.string :spot_type

      t.timestamps
    end
  end
end
