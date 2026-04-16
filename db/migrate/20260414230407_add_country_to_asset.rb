class AddCountryToAsset < ActiveRecord::Migration
  def change
   add_column :assets, :country, :string
  end
end
