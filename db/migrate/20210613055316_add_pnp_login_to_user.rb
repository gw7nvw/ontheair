class AddPnpLoginToUser < ActiveRecord::Migration
  def change
    add_column :users, :allow_pnp_login, :boolean
  end
end
