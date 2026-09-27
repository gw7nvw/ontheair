class AddAllowMultiToAssetTypes < ActiveRecord::Migration[8.0]
  def change
    add_column :asset_types, :allow_multi, :boolean
  end
end
