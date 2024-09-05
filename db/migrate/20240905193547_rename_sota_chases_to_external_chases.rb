class RenameSotaChasesToExternalChases < ActiveRecord::Migration
  def change
     rename_column :sota_chases, :sota_activation_id, :external_activation_id
     rename_table  :sota_chases, :external_chases
  end
end
