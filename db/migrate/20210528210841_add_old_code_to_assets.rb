# typed: false
class AddOldCodeToAssets < ActiveRecord::Migration[5.0]
  def change
    add_column :assets, :old_code, :string
  end
end
