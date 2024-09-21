class AddScoreFieldsToLog < ActiveRecord::Migration
  def change
    add_column :logs, :asset_classes, :string, array: true, default: []
    add_column :logs, :qualified, :boolean, array: true, default: []
  end
end
