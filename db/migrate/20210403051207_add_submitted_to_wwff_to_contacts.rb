# typed: false
class AddSubmittedToWwffToContacts < ActiveRecord::Migration
  def change
   add_column :contacts, :submitted_to_wwff, :boolean

  end
end
