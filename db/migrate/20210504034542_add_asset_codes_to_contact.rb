class AddAssetCodesToContact < ActiveRecord::Migration
  def change
    add_column :contacts, :asset1_codes, :string, array: true, default: []
    add_column :contacts, :asset2_codes, :string, array: true, default: []
  end
end
