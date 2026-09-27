class CreateAssetOverlaps < ActiveRecord::Migration[8.0]
  def change
        create_table :asset_overlaps do |t|
      t.string "contained_code"
      t.string "containing_code"
      t.float  "overlap"
    end

  end
end
