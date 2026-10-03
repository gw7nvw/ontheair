# typed: false
class AddPointsToAssets < ActiveRecord::Migration[5.0]
  def change
    add_column :assets, :points, :integer
  end
end
