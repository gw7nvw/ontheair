class AddSubmittedToLlotaToUser < ActiveRecord::Migration[5.0]
  def change
   add_column :contacts, :submitted_to_llota, :boolean
  end
end
