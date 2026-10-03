# typed: false
class AddMinQsoToAssetType < ActiveRecord::Migration[5.0]
  def change
    add_column :asset_types, :min_qso, :integer
  end
end
