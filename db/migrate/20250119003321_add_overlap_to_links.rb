class AddOverlapToLinks < ActiveRecord::Migration[5.0]
  def change
    add_column :asset_links, :overlap, :float
  end
end
