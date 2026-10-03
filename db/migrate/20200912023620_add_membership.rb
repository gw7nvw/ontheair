# typed: false
class AddMembership < ActiveRecord::Migration[5.0]
  def change
    add_column :users, :membership_requested, :boolean
    add_column :users, :membership_confirmed, :boolean
    add_column :users, :home_qth, :string
  end
end
