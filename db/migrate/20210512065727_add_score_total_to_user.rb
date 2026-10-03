# typed: false
class AddScoreTotalToUser < ActiveRecord::Migration[5.0]
  def change
    add_column :users, :score_total, :string
  end
end
