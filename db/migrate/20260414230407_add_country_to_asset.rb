class AddCountryToAsset < ActiveRecord::Migration[5.0]
  def change
   add_column :assets, :country, :string
  end
end
