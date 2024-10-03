# typed: false
class AddQualifiedToUser < ActiveRecord::Migration
  def change
    add_column :users, :qualified_count, :string
    add_column :users, :qualified_count_total, :string
  end
end
