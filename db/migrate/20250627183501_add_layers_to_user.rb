class AddLayersToUser < ActiveRecord::Migration
  def change
    add_column :users, :polygonlayers, :string
    add_column :users, :pointlayers, :string
  end
end
