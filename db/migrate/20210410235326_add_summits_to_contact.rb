# typed: false
class AddSummitsToContact < ActiveRecord::Migration[5.0]
  def change
   add_column :contacts, :submitted_to_sota, :boolean
   add_column :contacts, :summit1_id, :integer
   add_column :contacts, :summit2_id, :integer

  end
end
