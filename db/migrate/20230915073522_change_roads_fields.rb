# typed: false
class ChangeRoadsFields < ActiveRecord::Migration[5.0]
  def change
    drop_table :roads
  end
end
