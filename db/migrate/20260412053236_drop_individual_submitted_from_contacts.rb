class DropIndividualSubmittedFromContacts < ActiveRecord::Migration[5.0]
  def change
    remove_column :contacts, :submitted_to_sota
    remove_column :contacts, :submitted_to_pota
    remove_column :contacts, :submitted_to_llota
    remove_column :contacts, :submitted_to_wwff
    remove_column :contacts, :submitted_to_hema
    remove_column :contacts, :submitted_to_hema_chaser
  end
end
