class AddOcsToPost < ActiveRecord::Migration[8.0]
  def change
    add_column :posts, :is_portable, :boolean
    add_column :posts, :is_qrp, :boolean
    add_column :posts, :is_mobile, :boolean
  end
end
