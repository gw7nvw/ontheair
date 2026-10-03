# typed: false
class AddQualifiedToUser < ActiveRecord::Migration[5.0]
  def change
    add_column :users, :qualified_count, :string
    add_column :users, :qualified_count_total, :string
  end
end
