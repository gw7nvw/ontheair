# typed: false
class AddLocartionToUpload < ActiveRecord::Migration[5.0]
  def change
    add_column :uploads, :doc_location, :string
  end
end
