class AddIslandsBagged < ActiveRecord::Migration
  def change
    add_column :users, :islands_bagged, :integer
  end
end
