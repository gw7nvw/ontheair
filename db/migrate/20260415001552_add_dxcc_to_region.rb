class AddDxccToRegion < ActiveRecord::Migration
  def change
    add_column :regions, :dxcc, :string
    add_column :districts, :dxcc, :string
  end
end
