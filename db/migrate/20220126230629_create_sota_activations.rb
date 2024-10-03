# typed: false
class CreateSotaActivations < ActiveRecord::Migration
  def change
    create_table :sota_activations do |t|
      t.string :callsign
      t.string :summit_code
      t.integer :summit_sota_id 
      t.date :date
      t.integer :qso_count

      t.timestamps
    end
  end
end
