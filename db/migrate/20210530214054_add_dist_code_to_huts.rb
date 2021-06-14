class AddDistCodeToHuts < ActiveRecord::Migration
  def change
    add_column :huts, :dist_code, :string
  end
end
