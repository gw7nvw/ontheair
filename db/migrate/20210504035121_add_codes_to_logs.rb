class AddCodesToLogs < ActiveRecord::Migration
  def change
    add_column :logs, :asset_codes, :string, array: true, default: []
  end
end
