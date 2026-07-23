class AddApikeyToUsers < ActiveRecord::Migration
  def change
    add_column :users, :pnp_APIKey, :string
    add_column :users, :pnp_imported, :boolean, default: false
    add_column :users, :pnp_username, :string
  end
end
