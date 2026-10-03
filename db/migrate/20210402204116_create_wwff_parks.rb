# typed: false
class CreateWwffParks < ActiveRecord::Migration[5.0]
  def change
    create_table :wwff_parks do |t|
      t.string :code
      t.string :name
      t.string :dxcc
      t.string :region
      t.string :notes
      t.integer :napalis_id

      t.timestamps
    end
  end
end
