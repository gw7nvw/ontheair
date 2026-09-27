class AddAllowMultiToAssetTypes < ActiveRecord::Migration
  def change
    add_column :asset_types, :allow_multi, :boolean
  end
end
