# typed: false
class AddSubmittedToPotaToContact < ActiveRecord::Migration
  def change
   add_column :contacts, :submitted_to_pota, :boolean

  end
end
