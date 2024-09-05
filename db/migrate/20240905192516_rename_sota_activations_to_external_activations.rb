class RenameSotaActivationsToExternalActivations < ActiveRecord::Migration
  def change
     rename_column :sota_activations, :sota_activation_id, :external_activation_id
     rename_table :sota_activations, :external_activations
  end
end
