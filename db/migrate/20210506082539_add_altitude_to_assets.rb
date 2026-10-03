# typed: false
class AddAltitudeToAssets < ActiveRecord::Migration[5.0]
  def change
    add_column :assets, :altitude, :integer
  end
end
