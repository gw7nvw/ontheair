class AddLikePaternToAssetType < ActiveRecord::Migration
  def change
    add_column :asset_types, :like_pattern, :string
  end
end
