# typed: false
class AddLandDistrictToAsset < ActiveRecord::Migration[5.0]
  def change
    add_column :assets, :land_district, :string
  end
end
