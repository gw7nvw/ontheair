# typed: false
class AddPnpLoginToUser < ActiveRecord::Migration[5.0]
  def change
    add_column :users, :allow_pnp_login, :boolean
  end
end
