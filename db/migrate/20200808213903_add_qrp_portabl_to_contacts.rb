# typed: false
class AddQrpPortablToContacts < ActiveRecord::Migration
  def change
    add_column :contacts, :is_qrp1, :boolean
    add_column :contacts, :is_portable1, :boolean
    add_column :contacts, :is_qrp2, :boolean
    add_column :contacts, :is_portable2, :boolean

  end
end
