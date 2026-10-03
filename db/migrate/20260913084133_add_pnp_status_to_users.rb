class AddPnpStatusToUsers < ActiveRecord::Migration[5.0]
  def change
    add_column :users, :pnp_status, :string
  end
end
