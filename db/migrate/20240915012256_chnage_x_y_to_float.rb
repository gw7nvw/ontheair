# typed: false
class ChnageXYToFloat < ActiveRecord::Migration
  def change
    change_column :contacts, :x1, :float
    change_column :contacts, :y1, :float
    change_column :contacts, :x2, :float
    change_column :contacts, :y2, :float
  end
end
