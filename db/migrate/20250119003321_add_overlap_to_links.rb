class AddOverlapToLinks < ActiveRecord::Migration
  def change
    add_column :asset_links, :overlap, :float
  end
end
