# typed: false
class AddAreaToAsset < ActiveRecord::Migration[5.0]
  def change
     add_column :assets, :area, :float
  end
end
