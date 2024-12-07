class AddDoNotLookupToContacts < ActiveRecord::Migration
  def change
    add_column :contacts, :do_not_lookup, :boolean
  end
end
