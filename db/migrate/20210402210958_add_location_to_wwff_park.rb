class AddLocationToWwffPark < ActiveRecord::Migration
  def change
    change_table(:wwff_parks) do |t|
      t.point :location, :spatial => true, :srid => 4326
    end

  end
end
