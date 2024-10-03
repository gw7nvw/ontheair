# typed: false
class AddCallsignToUpload < ActiveRecord::Migration
  def change
     add_column :uploads, :doc_callsign, :string
     add_column :uploads, :doc_no_create, :boolean
     add_column :uploads, :doc_ignore_error, :boolean
  end
end
