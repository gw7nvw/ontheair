class AddPnpToExternalSpots < ActiveRecord::Migration[5.0]
  def change
    add_column :external_spots, :is_pnp, :boolean
  end
end
