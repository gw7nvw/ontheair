# typed: false
class AddSpotsToAdminSettings < ActiveRecord::Migration[5.0]
  def change
    add_column :admin_settings, :last_spot_read, :datetime
  end
end
