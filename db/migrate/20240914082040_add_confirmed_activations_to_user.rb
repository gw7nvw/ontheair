# typed: false
class AddConfirmedActivationsToUser < ActiveRecord::Migration[5.0]
  def change
    add_column :users, :confirmed_activated_count, :string
    add_column :users, :confirmed_activated_count_total, :string
  end
end
