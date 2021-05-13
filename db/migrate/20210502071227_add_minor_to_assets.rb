class AddMinorToAssets < ActiveRecord::Migration
  def change
    add_column :assets, :minor, :boolean
  end
end
