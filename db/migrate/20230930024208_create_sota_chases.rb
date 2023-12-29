class CreateSotaChases < ActiveRecord::Migration
  def change
    create_table :sota_chases do |t|
      t.string :callsign
      t.string :summit_code
      t.integer :summit_sota_id
      t.integer :user_id
      t.integer :sota_activation_id
      t.string :band
      t.string :mode
      t.date :date
      t.time :time

      t.timestamps
    end
  end
end
