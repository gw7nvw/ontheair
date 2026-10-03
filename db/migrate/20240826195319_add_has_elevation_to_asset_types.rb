# typed: false
class AddHasElevationToAssetTypes < ActiveRecord::Migration[5.0]
  def change
   add_column :asset_types, :has_elevation, :boolean
  end
end
