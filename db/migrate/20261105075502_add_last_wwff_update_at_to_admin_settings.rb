class AddLastWwffUpdateAtToAdminSettings < ActiveRecord::Migration[8.0]
  def change
    add_column :admin_settings, :last_wwff_update_id, :string
  end
end
