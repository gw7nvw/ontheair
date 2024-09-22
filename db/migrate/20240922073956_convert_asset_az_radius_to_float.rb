class ConvertAssetAzRadiusToFloat < ActiveRecord::Migration
  def change
    change_column :assets, :az_radius, :float

  end
end
