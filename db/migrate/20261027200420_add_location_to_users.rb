class AddLocationToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :location, :st_point, srid: 4326, geographic: false
  end
end
