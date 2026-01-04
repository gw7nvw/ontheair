class AddBugfixFieldsToConsolidatedSpot < ActiveRecord::Migration
  def change
    add_column :consolidated_spots, :old_spot_type, :string, default: [], array: true
    add_column :consolidated_spots, :band, :string
  end
end
