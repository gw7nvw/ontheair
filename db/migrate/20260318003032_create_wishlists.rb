class CreateWishlists < ActiveRecord::Migration[5.0]
  def change
    create_table :wishlists do |t|
      t.string "asset_code"
      t.integer "user_id"

      t.index :asset_code
      t.index :user_id

      t.timestamps
    end
  end
end
