# typed: false
class CreateUserCallsigns < ActiveRecord::Migration
  def change
    create_table :user_callsigns do |t|
      t.integer :user_id
      t.string :callsign
      t.datetime :from_date
      t.datetime :to_date

      t.timestamps
    end
  end
end

