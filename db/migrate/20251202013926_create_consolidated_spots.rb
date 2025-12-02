class CreateConsolidatedSpots < ActiveRecord::Migration
  def change
    create_table :consolidated_spots do |t|
      t.string   "time", default: [], array: true
      t.string   "callsign", default: [], array: true
      t.string   "activatorCallsign"
      t.string   "code", default: [], array: true
      t.string   "name", default: [], array: true
      t.string   "frequency"
      t.string   "mode"
      t.string   "comments", default: [], array: true
      t.string   "spot_type", default: [], array: true
      t.string   "post_id", default: [], array: true
      t.string   "points"
      t.string   "altM"

      t.timestamps
    end
  end
end
