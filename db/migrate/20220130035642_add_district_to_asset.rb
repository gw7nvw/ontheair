# typed: false
class AddDistrictToAsset < ActiveRecord::Migration[5.0]
  def change
    add_column :assets, :district, :string
  end
end
