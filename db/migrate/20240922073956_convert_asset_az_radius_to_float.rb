# typed: false
class ConvertAssetAzRadiusToFloat < ActiveRecord::Migration[5.0]
  def change
    change_column :assets, :az_radius, :float

  end
end
