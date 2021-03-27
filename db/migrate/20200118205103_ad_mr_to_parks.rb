class AdMrToParks < ActiveRecord::Migration
  def change
    add_column :parks, :is_mr, :boolean
  end
end
