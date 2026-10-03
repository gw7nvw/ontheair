class AddSourceIdToExternalAlert < ActiveRecord::Migration[5.0]
  def change
    add_column :external_alerts, :source, :string
    add_column :external_alerts, :source_id, :integer
  end
end
