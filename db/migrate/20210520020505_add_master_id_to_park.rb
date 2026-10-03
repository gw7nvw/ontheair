# typed: false
class AddMasterIdToPark < ActiveRecord::Migration[5.0]
  def change
    add_column :parks, :master_id, :integer
    add_column :assets, :master_code, :string
  end
end
