# typed: false
class AddSpotsToAdminSettings < ActiveRecord::Migration
  def change
    add_column :admin_settings, :last_spot_read, :datetime
  end
end
