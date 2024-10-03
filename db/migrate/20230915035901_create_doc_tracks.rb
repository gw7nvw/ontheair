# typed: false
class CreateDocTracks < ActiveRecord::Migration
  def change
    create_table :doc_tracks do |t|
      t.spatial :linestring,     limit: {:srid=>4326, :type=>"multi_linestring"}
      t.string :name
      t.string :object_type

      t.timestamps
    end
  end
end
