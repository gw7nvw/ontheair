# typed: false
class AddUserIdToSotaActivation < ActiveRecord::Migration[5.0]
  def change
    add_column :sota_activations, :user_id, :integer
  end
end
