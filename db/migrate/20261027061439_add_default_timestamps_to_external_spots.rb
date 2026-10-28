class AddDefaultTimestampsToExternalSpots < ActiveRecord::Migration[8.0]
  def change
    change_column_default :external_spots, :created_at, -> { 'NOW()' }
    change_column_default :external_spots, :updated_at, -> { 'NOW()' }
  end
end
