class AddSubmittedToToContacts < ActiveRecord::Migration[5.0]
  def change
    add_column :contacts, :submitted_to, :string, default: [], array: true
  end
end
