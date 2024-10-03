# typed: false
class AddNamesToContacts < ActiveRecord::Migration
  def change
    add_column :contacts, :name1, :string
    add_column :contacts, :name2, :string

  end
end
