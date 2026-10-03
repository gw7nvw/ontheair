# typed: false
class AddCategoryToAssets < ActiveRecord::Migration[5.0]
  def change
    add_column :assets, :category, :string
  end
end
