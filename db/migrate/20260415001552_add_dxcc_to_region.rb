class AddDxccToRegion < ActiveRecord::Migration[5.0]
  def change
    add_column :regions, :dxcc, :string
    add_column :districts, :dxcc, :string
  end
end
