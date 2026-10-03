# typed: false
class AddActivatedChasedToUser < ActiveRecord::Migration[5.0]
  def change
    add_column :users, :activated_count, :string
    add_column :users, :activated_count_total, :string
    add_column :users, :chased_count, :string
    add_column :users, :chased_count_total, :string
  end
end
