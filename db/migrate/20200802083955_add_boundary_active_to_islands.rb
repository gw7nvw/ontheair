class AddBoundaryActiveToIslands < ActiveRecord::Migration
  def change
    add_column :islands, :is_active, :boolean, default: true
    add_column :islands, :general_link, :string
    add_column :huts, :island_id, :integer
    add_column :contacts, :island1_id, :integer
    add_column :contacts, :island2_id, :integer
  end
end
