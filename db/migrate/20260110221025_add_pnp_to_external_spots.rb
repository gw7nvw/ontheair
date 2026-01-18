class AddPnpToExternalSpots < ActiveRecord::Migration
  def change
    add_column :external_spots, :is_pnp, :boolean
  end
end
