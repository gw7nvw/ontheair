class AddSpotterCallsignToPosts < ActiveRecord::Migration[8.0]
  def change
    add_column :posts, :spotter_callsign, :string
  end
end
