class AddDxccToConsolidatedSpots < ActiveRecord::Migration
  def change
    add_column :consolidated_spots, :dxcc, :string
  end
end
