class AddClassToContacts < ActiveRecord::Migration
  def change
    add_column :contacts, :asset1_classes, :string, array: true, default: [] 
    add_column :contacts, :asset2_classes, :string, array: true, default: []
  end
end
