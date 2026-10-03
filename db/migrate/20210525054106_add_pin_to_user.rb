# typed: false
class AddPinToUser < ActiveRecord::Migration[5.0]
  def change
    add_column :users, :pin, :string
  end
end
