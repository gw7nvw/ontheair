class ChangeAssetsNearestRoadIdToString < ActiveRecord::Migration[8.0]
  def change
    change_column :assets, :nearest_road_id, :string
  end
end
