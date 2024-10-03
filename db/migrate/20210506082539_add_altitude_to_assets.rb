# typed: false
class AddAltitudeToAssets < ActiveRecord::Migration
  def change
    add_column :assets, :altitude, :integer
  end
end
