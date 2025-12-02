class CreateConsolodatedSpots < ActiveRecord::Migration
  def change
    create_table :consolodated_spots do |t|
      t.datetime "time", default: [], array: true
      t.string   "callsign", default: [], array: true
      t.string   "activatorCallsign"
      t.string   "code", default: [], array: true
      t.string   "name", default: [], array: true
      t.string   "frequency"
      t.string   "mode"
      t.string   "comments", default: [], array: true
      t.string   "spot_type", default: [], array: true
      t.string   "points"
      t.string   "altM"

      t.timestamps
    end
  end
end
