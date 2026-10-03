# typed: false
class AddAzRadius < ActiveRecord::Migration[5.0]
  def change
    add_column :assets, :az_radius, :integer
  end
end
