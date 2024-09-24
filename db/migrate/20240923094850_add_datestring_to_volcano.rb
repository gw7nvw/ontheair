class AddDatestringToVolcano < ActiveRecord::Migration
  def change
    add_column :volcanos, :date_range, :string

  end
end
