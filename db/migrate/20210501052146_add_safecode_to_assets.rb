class AddSafecodeToAssets < ActiveRecord::Migration
  def change
    add_column :assets, :safecode, :string
  end
end
