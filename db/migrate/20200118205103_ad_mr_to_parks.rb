# typed: false
class AdMrToParks < ActiveRecord::Migration[5.0]
  def change
    add_column :parks, :is_mr, :boolean
  end
end
