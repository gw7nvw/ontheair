# typed: false
class AddDatestringToVolcano < ActiveRecord::Migration[5.0]
  def change
    add_column :volcanos, :date_range, :string

  end
end
