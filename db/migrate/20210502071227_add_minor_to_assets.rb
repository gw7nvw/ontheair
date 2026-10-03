# typed: false
class AddMinorToAssets < ActiveRecord::Migration[5.0]
  def change
    add_column :assets, :minor, :boolean
  end
end
