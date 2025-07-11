class CreateExternalAlerts < ActiveRecord::Migration
  def change
    create_table :external_alerts do |t|

      t.datetime "starttime"
      t.string "activatingCallsign"
      t.string "code"
      t.string "name"
      t.string "frequency"
      t.string "comments"
      t.string "type"
 
      t.timestamps
    end
  end
end
