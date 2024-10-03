# typed: false
class AddMembership < ActiveRecord::Migration
  def change
    add_column :users, :membership_requested, :boolean
    add_column :users, :membership_confirmed, :boolean
    add_column :users, :home_qth, :string
  end
end
