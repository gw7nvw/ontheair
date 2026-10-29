class AddOcFlagsToConsolidatedSpots < ActiveRecord::Migration[8.0]
  def change
    add_column :consolidated_spots, :is_portable, :boolean
    add_column :consolidated_spots, :is_qrp, :boolean
    add_column :consolidated_spots, :is_mobile, :boolean
  end
end
