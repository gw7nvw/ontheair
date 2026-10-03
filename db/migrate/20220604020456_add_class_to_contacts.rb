# typed: false
class AddClassToContacts < ActiveRecord::Migration[5.0]
  def change
    add_column :contacts, :asset1_classes, :string, array: true, default: [] 
    add_column :contacts, :asset2_classes, :string, array: true, default: []
  end
end
