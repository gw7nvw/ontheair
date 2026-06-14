class AddDxccToExternalAlerts < ActiveRecord::Migration
  def change
    add_column :external_alerts, :dxcc, :string
  end
end
