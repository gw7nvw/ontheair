# typed: false
class AddIndexToLogsContacts < ActiveRecord::Migration[5.0]
  def change
    add_index :logs, :date
    add_index :contacts, :date
  end
end
