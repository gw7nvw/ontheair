class AddConfirmedActivationsToUser < ActiveRecord::Migration
  def change
    add_column :users, :confirmed_activated_count, :string
    add_column :users, :confirmed_activated_count_total, :string
  end
end
