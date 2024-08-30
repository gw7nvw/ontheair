class AddHasElevationToAssetTypes < ActiveRecord::Migration
  def change
   add_column :asset_types, :has_elevation, :boolean
  end
end
