class AddDoNotLookupToContacts < ActiveRecord::Migration[5.0]
  def change
    add_column :contacts, :do_not_lookup, :boolean
  end
end
