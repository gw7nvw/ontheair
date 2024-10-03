# typed: false
class CreateHumps < ActiveRecord::Migration
  def change
    create_table :humps do |t|
      t.string :dxcc
      t.string :region
      t.string :code
      t.string :name
      t.string :elevation
      t.string :prominence
      t.point :location, :spatial => true, :srid => 4326

      t.timestamps
    end
  end

end
