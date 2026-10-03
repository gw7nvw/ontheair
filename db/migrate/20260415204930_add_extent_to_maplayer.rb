class AddExtentToMaplayer < ActiveRecord::Migration[5.0]
  def change
     add_column :maplayers, :extent, :string
  end
end
