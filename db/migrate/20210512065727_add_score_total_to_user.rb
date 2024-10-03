# typed: false
class AddScoreTotalToUser < ActiveRecord::Migration
  def change
    add_column :users, :score_total, :string
  end
end
