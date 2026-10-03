# typed: false
class AddLocSrcToLogContacts < ActiveRecord::Migration[5.0]
  def change
   add_column :contacts, :loc_source2, :string
   add_column :logs, :loc_source, :string
  end
end
