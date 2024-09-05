class AddBandToContact < ActiveRecord::Migration
  def change
   add_column :contacts, :band, :string
  end
end
