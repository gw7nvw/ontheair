# typed: false
class AddDistCodeToPark < ActiveRecord::Migration[5.0]
  def change
     add_column :parks, :dist_code, :string
     add_column :parks, :land_district, :string
  end
end
