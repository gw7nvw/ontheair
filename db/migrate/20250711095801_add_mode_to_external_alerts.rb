class AddModeToExternalAlerts < ActiveRecord::Migration
  def change
    add_column :external_alerts, :mode, :string
    add_column :external_alerts, :programme, :string
    add_column :external_alerts, :duration, :string
    remove_column :external_alerts, :type, :string
  end
end
