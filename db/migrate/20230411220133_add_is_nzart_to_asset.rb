# typed: false
class AddIsNzartToAsset < ActiveRecord::Migration[5.0]
  def change
    add_column :assets, :is_nzart, :boolean
  end
end
