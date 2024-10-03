# typed: false
class AddPointsToAssets < ActiveRecord::Migration
  def change
    add_column :assets, :points, :integer
  end
end
