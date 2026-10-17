class CreateAssetProtectedAreaLinkTable < ActiveRecord::Migration[8.0]
  def change
    create_table :asset_protected_area_links do |t|
      t.string :asset_code, null: false
      t.bigint :napalis_id, null: false
      t.timestamps
    end

    add_index :asset_protected_area_links, :napalis_id, unique: true
    add_index :asset_protected_area_links, :asset_code
  end
end
