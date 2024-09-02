class AddLocSrcToLogContacts < ActiveRecord::Migration
  def change
   add_column :contacts, :loc_source2, :string
   add_column :logs, :loc_source, :string
  end
end
