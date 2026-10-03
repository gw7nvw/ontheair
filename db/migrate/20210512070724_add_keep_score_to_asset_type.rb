# typed: false
class AddKeepScoreToAssetType < ActiveRecord::Migration[5.0]
  def change
    add_column :asset_types, :keep_score, :boolean
  end
end
