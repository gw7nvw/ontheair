class AddOldCodeToAssets < ActiveRecord::Migration
  def change
    add_column :assets, :old_code, :string
  end
end
