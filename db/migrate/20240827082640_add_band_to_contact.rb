# typed: false
class AddBandToContact < ActiveRecord::Migration[5.0]
  def change
   add_column :contacts, :band, :string
  end
end
