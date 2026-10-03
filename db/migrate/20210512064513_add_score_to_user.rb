# typed: false
class AddScoreToUser < ActiveRecord::Migration[5.0]
  def change
    add_column :users, :score, :string
  end
end
