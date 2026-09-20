class AddPnpStatusToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :pnp_status, :string
  end
end
