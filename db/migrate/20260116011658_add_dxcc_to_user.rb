class AddDxccToUser < ActiveRecord::Migration[5.0]
  def change
    add_column :users, :dxcc, :string
  end
end
