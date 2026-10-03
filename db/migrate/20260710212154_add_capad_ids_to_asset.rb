class AddCapadIdsToAsset < ActiveRecord::Migration[5.0]
  def change
    add_column :assets, :access_capad_park_ids, :string, array: true, default: []
    add_column :assets, :access_vk_state_park_ids, :string, array: true, default: []
  end
end
