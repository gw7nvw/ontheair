class AddDxccToExternalAlerts < ActiveRecord::Migration[5.0]
  def change
    add_column :external_alerts, :dxcc, :string
  end
end
