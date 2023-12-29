class AddActIdToSotaAct < ActiveRecord::Migration
  def change
    add_column :sota_activations, :sota_activation_id, :integer

  end
end
