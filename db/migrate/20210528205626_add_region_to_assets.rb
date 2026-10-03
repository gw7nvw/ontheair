# typed: false
class AddRegionToAssets < ActiveRecord::Migration[5.0]
  def change
    add_column :assets, :region, :string
    add_column :parks, :region, :string
    add_column :huts, :region, :string
  end
end
