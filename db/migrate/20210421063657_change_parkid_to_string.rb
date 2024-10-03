# typed: false
class ChangeParkidToString < ActiveRecord::Migration
  def change
   change_column :contacts, :park1_id, :string
   change_column :contacts, :park2_id, :string

  end
end
