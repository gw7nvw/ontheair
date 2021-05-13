class AddCategoryToAssets < ActiveRecord::Migration
  def change
    add_column :assets, :category, :string
  end
end
