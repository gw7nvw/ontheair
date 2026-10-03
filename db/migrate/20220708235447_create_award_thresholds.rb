# typed: false
class CreateAwardThresholds < ActiveRecord::Migration[5.0]
  def change
    create_table :award_thresholds do |t|
      t.integer  :threshold
      t.string :name
      t.timestamps
    end
  end
end
