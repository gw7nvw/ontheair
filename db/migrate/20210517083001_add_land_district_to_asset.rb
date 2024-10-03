# typed: false
class AddLandDistrictToAsset < ActiveRecord::Migration
  def change
    add_column :assets, :land_district, :string
  end
end
