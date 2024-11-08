class AddUrlToVolcanicFields < ActiveRecord::Migration
  def change
    add_column :volcanic_fields, :url, :string
  end
end
