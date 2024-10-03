# typed: false
class AddRepeatVisitToAward < ActiveRecord::Migration
  def change
    add_column :awards, :allow_repeat_visits, :boolean
    add_column :users, :huts_bagged_total, :integer
    add_column :users, :parks_bagged_total, :integer
    add_column :users, :islands_bagged_total, :integer
  end
end
