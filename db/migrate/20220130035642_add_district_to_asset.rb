# typed: false
class AddDistrictToAsset < ActiveRecord::Migration
  def change
    add_column :assets, :district, :string
  end
end
