# typed: false
class RenameSotaChasesToExternalChases < ActiveRecord::Migration[5.0]
  def change
     rename_column :sota_chases, :sota_activation_id, :external_activation_id
     rename_table  :sota_chases, :external_chases
  end
end
