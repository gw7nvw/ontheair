# typed: false
class UpdateAwards < ActiveRecord::Migration
  def change
    remove_column :awards, :huts_minimum, :integer
    remove_column :awards, :islands_minimum, :integer
    remove_column :awards, :parks_minimum, :integer
    add_column :awards, :count_based, :boolean
    add_column :awards, :activated, :boolean
    add_column :awards, :chased, :boolean
    add_column :awards, :programme, :string
    add_column :awards, :all_district, :boolean
    add_column :awards, :all_region, :boolean
    add_column :awards, :all_programme, :boolean
    add_column :awards, :p2p, :boolean
  end
end
