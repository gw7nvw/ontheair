# typed: false
class CreateDocTracks < ActiveRecord::Migration[5.0]
  def change
    create_table :doc_tracks do |t|
      t.line_string :linestring,     :srid=>4326, :spatial => true
      t.string :name
      t.string :object_type

      t.timestamps
    end
  end
end
