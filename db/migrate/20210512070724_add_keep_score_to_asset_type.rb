# typed: false
class AddKeepScoreToAssetType < ActiveRecord::Migration
  def change
    add_column :asset_types, :keep_score, :boolean
  end
end
