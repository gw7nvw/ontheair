# typed: false
class ChangeRoadsFields < ActiveRecord::Migration
  def change
    drop_table :roads
  end
end
