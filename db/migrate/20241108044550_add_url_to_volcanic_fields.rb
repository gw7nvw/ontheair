class AddUrlToVolcanicFields < ActiveRecord::Migration[5.0]
  def change
    add_column :volcanic_fields, :url, :string
  end
end
