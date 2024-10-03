# typed: false
class AddAzRadius < ActiveRecord::Migration
  def change
    add_column :assets, :az_radius, :integer
  end
end
