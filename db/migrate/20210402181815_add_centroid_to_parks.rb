class AddCentroidToParks < ActiveRecord::Migration
  def change
    change_table(:parks) do |t|
      t.point :location, :spatial => true, :srid => 4326
    end
  end
end
