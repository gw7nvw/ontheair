# typed: false
class AddSubmittedToHema < ActiveRecord::Migration
  def change
   add_column :contacts, :submitted_to_hema, :boolean

  end
end
