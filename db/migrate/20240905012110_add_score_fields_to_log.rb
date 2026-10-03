# typed: false
class AddScoreFieldsToLog < ActiveRecord::Migration[5.0]
  def change
    add_column :logs, :asset_classes, :string, array: true, default: []
    add_column :logs, :qualified, :boolean, array: true, default: []
  end
end
