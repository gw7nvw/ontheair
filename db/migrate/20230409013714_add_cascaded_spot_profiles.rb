# typed: false
class AddCascadedSpotProfiles < ActiveRecord::Migration
  def change
    add_column :users, :logs_pota, :boolean
    add_column :users, :logs_wwff, :boolean
  end
end
