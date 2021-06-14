class AddAreaToAsset < ActiveRecord::Migration
  def change
     add_column :assets, :area, :float
  end
end
