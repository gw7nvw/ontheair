# typed: false
class AddActIdToSotaAct < ActiveRecord::Migration[5.0]
  def change
    add_column :sota_activations, :sota_activation_id, :integer

  end
end
