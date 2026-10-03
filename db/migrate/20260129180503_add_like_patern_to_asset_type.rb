class AddLikePaternToAssetType < ActiveRecord::Migration[5.0]
  def change
    add_column :asset_types, :like_pattern, :string
  end
end
