class AddDxccToUser < ActiveRecord::Migration
  def change
    add_column :users, :dxcc, :string
  end
end
