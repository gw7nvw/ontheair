# typed: false
class CreateGeologicalEras < ActiveRecord::Migration
  def change
    create_table :geological_eras do |t|
      t.string :name
      t.float :start_mya
      t.float :end_mya

      t.timestamps
    end
  end
end
