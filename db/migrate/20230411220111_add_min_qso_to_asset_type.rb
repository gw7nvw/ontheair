# typed: false
class AddMinQsoToAssetType < ActiveRecord::Migration
  def change
    add_column :asset_types, :min_qso, :integer
  end
end
