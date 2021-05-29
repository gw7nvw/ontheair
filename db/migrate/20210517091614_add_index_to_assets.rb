class AddIndexToAssets < ActiveRecord::Migration
  def self.up
    add_index :assets, :safecode
    add_index :asset_types, :name
    add_index :users, :callsign
    add_index :contacts, :callsign1
    add_index :contacts, :callsign2
  end

  def self.down
    remove_index :assets, :safecode
    remove_index :asset_types, :name
    remove_index :users, :callsign
    remove_index :contacts, :callsign1
    remove_index :contacts, :callsign2
  end
end
