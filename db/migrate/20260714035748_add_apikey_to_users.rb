class AddApikeyToUsers < ActiveRecord::Migration[5.0]
  def change
    add_column :users, :pnp_APIKey, :string
    add_column :users, :pnp_imported, :boolean, default: false
    add_column :users, :pnp_username, :string
  end
end
