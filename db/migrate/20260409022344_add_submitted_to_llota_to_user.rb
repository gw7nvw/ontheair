class AddSubmittedToLlotaToUser < ActiveRecord::Migration
  def change
   add_column :contacts, :submitted_to_llota, :boolean
  end
end
