class AddSubmittedToHemaChaserToContact < ActiveRecord::Migration[5.0]
  def change
    add_column :contacts, :submitted_to_hema_chaser, :boolean
  end
end
