class AddLayersToUser < ActiveRecord::Migration[5.0]
  def change
    add_column :users, :polygonlayers, :string
    add_column :users, :pointlayers, :string
  end
end
