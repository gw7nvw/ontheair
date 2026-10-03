# typed: false
class AddReadOnlyToUsers < ActiveRecord::Migration[5.0]
  def change
    add_column :users, :read_only, :boolean
  end
end
