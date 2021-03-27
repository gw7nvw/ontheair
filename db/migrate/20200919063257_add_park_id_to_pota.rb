class AddParkIdToPota < ActiveRecord::Migration
  def change
    add_column :pota_parks, :park_id, :integer
  end
end
