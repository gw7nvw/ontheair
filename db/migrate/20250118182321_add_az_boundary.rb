class AddAzBoundary < ActiveRecord::Migration[5.0]
  def change
    add_column :assets, :az_boundary, :spatial,  limit: {:srid=>4326, :type=>"multi_polygon"}
    add_column :assets, :az_area, :float
  end
end
