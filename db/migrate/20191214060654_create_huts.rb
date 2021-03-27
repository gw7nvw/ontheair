class CreateHuts < ActiveRecord::Migration
  def change
    create_table :huts do |t|
      t.string :name
      t.string :hutbagger_link
      t.string :doc_link
      t.string :tramper_link
      t.string :routeguides_link
      t.string :general_link
      t.text :description
      t.float :x
      t.float :y
      t.integer :altitude
      t.integer :park_id
      t.point :location, :spatial => true, :srid => 4326
      t.boolean :is_active, default: true
      t.boolean :is_doc, default: true

      t.integer :createdBy_id

      t.timestamps

    end
  end
end
