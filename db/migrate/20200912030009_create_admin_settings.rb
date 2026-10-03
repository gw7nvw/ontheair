# typed: false
class CreateAdminSettings < ActiveRecord::Migration[5.0]
  def change
    create_table :admin_settings do |t|
      t.string :qrpnz_email
      t.string :admin_email
      t.timestamps
    end
  end
end
