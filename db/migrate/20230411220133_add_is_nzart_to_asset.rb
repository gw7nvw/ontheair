# typed: false
class AddIsNzartToAsset < ActiveRecord::Migration
  def change
    add_column :assets, :is_nzart, :boolean
  end
end
