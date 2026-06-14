class AddContinentToSpotsAlertd < ActiveRecord::Migration
  def change
    add_column :consolidated_spots, :continent, :string
    add_column :external_alerts, :continent, :string
  end
end
