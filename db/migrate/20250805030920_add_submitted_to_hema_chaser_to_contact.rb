class AddSubmittedToHemaChaserToContact < ActiveRecord::Migration
  def change
    add_column :contacts, :submitted_to_hema_chaser, :boolean
  end
end
