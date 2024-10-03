# typed: false
class CreateParks < ActiveRecord::Migration
  def change
    create_table :parks do |t|
      t.string :name
      t.string :doc_link
      t.string :tramper_link
      t.string :general_link
      t.text :description
      t.multi_polygon :boundary, :spatial => true, :srid => 4326

      t.boolean :is_active, default: true
      t.integer :createdBy_id


      t.timestamps
    end
  end
end
