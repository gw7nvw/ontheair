class AddUserIdToSotaActivation < ActiveRecord::Migration
  def change
    add_column :sota_activations, :user_id, :integer
  end
end
