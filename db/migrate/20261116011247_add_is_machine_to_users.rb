class AddIsMachineToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :is_machine, :boolean
  end
end
