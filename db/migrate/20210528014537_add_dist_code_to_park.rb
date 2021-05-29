class AddDistCodeToPark < ActiveRecord::Migration
  def change
     add_column :parks, :dist_code, :string
     add_column :parks, :land_district, :string
  end
end
