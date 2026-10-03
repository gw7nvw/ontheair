# typed: false
class AddIslandsBagged < ActiveRecord::Migration[5.0]
  def change
    add_column :users, :islands_bagged, :integer
  end
end
