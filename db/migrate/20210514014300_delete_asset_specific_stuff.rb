# typed: false
class DeleteAssetSpecificStuff < ActiveRecord::Migration
  def change
    remove_column :contacts, :hut1_id
    remove_column :contacts, :island1_id
    remove_column :contacts, :park1_id
    remove_column :contacts, :summit1_id
    remove_column :contacts, :hut2_id
    remove_column :contacts, :island2_id
    remove_column :contacts, :park2_id
    remove_column :contacts, :summit2_id
    remove_column :contacts, :name1
    remove_column :contacts, :name2
    remove_column :huts, :park_id
    remove_column :huts, :island_id
    remove_column :logs, :hut1_id
    remove_column :logs, :island1_id
    remove_column :logs, :park1_id
    remove_column :logs, :summit1_id
    remove_column :sota_peaks, :park_id
    remove_column :sota_peaks, :island_id
    remove_column :users, :huts_bagged
    remove_column :users, :huts_bagged_total
    remove_column :users, :huts_first_bagged
    remove_column :users, :parks_bagged
    remove_column :users, :parks_bagged_total
    remove_column :users, :parks_first_bagged
    remove_column :users, :islands_bagged
    remove_column :users, :islands_bagged_total

  end
end
