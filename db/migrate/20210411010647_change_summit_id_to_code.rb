# typed: false
class ChangeSummitIdToCode < ActiveRecord::Migration[5.0]
  def change
   change_column :contacts, :summit1_id, :string
   change_column :contacts, :summit2_id, :string
  end
end
