class AddSubmittedToToContacts < ActiveRecord::Migration
  def change
    add_column :contacts, :submitted_to, :string, default: [], array: true
  end
end
