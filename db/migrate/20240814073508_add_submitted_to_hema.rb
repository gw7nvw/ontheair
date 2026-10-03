# typed: false
class AddSubmittedToHema < ActiveRecord::Migration[5.0]
  def change
   add_column :contacts, :submitted_to_hema, :boolean

  end
end
