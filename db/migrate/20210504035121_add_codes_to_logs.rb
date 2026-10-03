# typed: false
class AddCodesToLogs < ActiveRecord::Migration[5.0]
  def change
    add_column :logs, :asset_codes, :string, array: true, default: []
  end
end
