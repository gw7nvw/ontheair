class AddPnpStatusToUsers < ActiveRecord::Migration
  def change
    add_column :users, :pnp_status, :string
  end
end
