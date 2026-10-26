class AddKeysToExternalSpots < ActiveRecord::Migration[8.0]
  def change
    add_column :external_spots, :source_api, :string
    add_column :external_spots, :source_id, :string
        # Create the composite unique index that dictates conflict logic
    add_index :external_spots, [:source_api, :source_id], unique: true
  end
end
