class AddCountryToTribalLands < ActiveRecord::Migration
  def change
    add_column :nz_tribal_lands, :country, :string
  end
end
