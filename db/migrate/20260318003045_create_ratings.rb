class CreateRatings < ActiveRecord::Migration
  def change
    create_table :ratings do |t|
      t.boolean "drive_up_access"
      t.boolean "track_access"
      t.integer "accessibility_score"
      t.integer "nice_score"
      t.integer "user_id"
      t.string "asset_code"

      t.index :asset_code
      t.index :user_id

      t.timestamps
    end
  end
end
