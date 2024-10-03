# typed: false
class AddLocartionToUpload < ActiveRecord::Migration
  def change
    add_column :uploads, :doc_location, :string
  end
end
