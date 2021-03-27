class CreateContacts < ActiveRecord::Migration
  def change
    create_table :contacts do |t|
      t.string :callsign1
      t.integer :user1_id
      t.integer :power1
      t.string :signal1
      t.string :transceiver1
      t.string :antenna1
      t.string :comments1
      t.boolean :first_contact1, default: true
      t.string :loc_desc1
      t.integer :hut1_id
      t.integer :park1_id
      t.integer :x1
      t.integer :y1
      t.integer :altitude1 
      t.point :location1, :spatial => true, :srid => 4326

      t.string :callsign2
      t.integer :user2_id
      t.integer :power2
      t.string :signal2
      t.string :transceiver2
      t.string :antenna2
      t.string :comments2
      t.boolean :first_contact2, default: true
      t.string :loc_desc2
      t.integer :hut2_id
      t.integer :park2_id
      t.integer :x2
      t.integer :y2
      t.integer :altitude2 
      t.point :location2, :spatial => true, :srid => 4326

      t.datetime :date
      t.datetime :time
      t.string :timezone
      t.float :frequency
      t.string :mode


      t.boolean :is_active, default: true

      t.integer :createdBy_id

      t.timestamps
    end
  end

end
