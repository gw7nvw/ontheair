class AddDxccToConsolidatedSpots < ActiveRecord::Migration[5.0]
  def change
    add_column :consolidated_spots, :dxcc, :string
  end
end
