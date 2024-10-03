# typed: false
class AddIndexToLogsContacts < ActiveRecord::Migration
  def change
    add_index :logs, :date
    add_index :contacts, :date
  end
end
