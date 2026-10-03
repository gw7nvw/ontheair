class AddCopyrightToMaplayer < ActiveRecord::Migration[5.0]
  def change
    add_column :maplayers, :copyright_text, :string
    add_column :maplayers, :copyright_link, :string

  end
end
