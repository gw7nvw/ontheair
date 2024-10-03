# typed: false
class CreateLogs < ActiveRecord::Migration
  def change
    create_table :logs do |t|
    t.string   "callsign1"
    t.integer  "user1_id"
    t.integer  "power1"
    t.string   "signal1"
    t.string   "transceiver1"
    t.string   "antenna1"
    t.string   "comments1"
    t.boolean  "first_contact1",                                          default: true
    t.string   "loc_desc1"
    t.integer  "hut1_id"
    t.integer  "park1_id"
    t.integer  "x1"
    t.integer  "y1"
    t.integer  "altitude1"
    t.datetime "date"
    t.datetime "time"
    t.string   "timezone"
    t.float    "frequency"
    t.string   "mode"
    t.boolean  "is_active",                                               default: true
    t.integer  "createdBy_id"
    t.spatial  "location1",         limit: {:srid=>4326, :type=>"point"}
    t.integer  "island1_id"
    t.boolean  "is_qrp1"
    t.boolean  "is_portable1"
    t.string   "summit1_id"

      t.timestamps
    end

    add_column :contacts, :log_id, :integer

  end
end
