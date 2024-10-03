# typed: false
class AddMasterIdToPark < ActiveRecord::Migration
  def change
    add_column :parks, :master_id, :integer
    add_column :assets, :master_code, :string
  end
end
