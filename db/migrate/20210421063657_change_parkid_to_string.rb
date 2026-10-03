# typed: false
class ChangeParkidToString < ActiveRecord::Migration[5.0]
  def change
   change_column :contacts, :park1_id, :string
   change_column :contacts, :park2_id, :string

  end
end
