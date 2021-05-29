class AddRegionToAssets < ActiveRecord::Migration
  def change
    add_column :assets, :region, :string
    add_column :parks, :region, :string
    add_column :huts, :region, :string
  end
end
