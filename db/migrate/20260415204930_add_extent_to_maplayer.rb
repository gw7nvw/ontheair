class AddExtentToMaplayer < ActiveRecord::Migration
  def change
     add_column :maplayers, :extent, :string
  end
end
