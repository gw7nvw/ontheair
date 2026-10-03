# typed: false
class AddDistCodeToHuts < ActiveRecord::Migration[5.0]
  def change
    add_column :huts, :dist_code, :string
  end
end
