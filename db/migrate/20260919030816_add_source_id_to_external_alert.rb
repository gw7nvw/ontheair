class AddSourceIdToExternalAlert < ActiveRecord::Migration
  def change
    add_column :external_alerts, :source, :string
    add_column :external_alerts, :source_id, :integer
  end
end
