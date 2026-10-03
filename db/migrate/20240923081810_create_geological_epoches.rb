# typed: false
class CreateGeologicalEpoches < ActiveRecord::Migration[5.0]
  def change
    create_table :geological_epoches do |t|
      t.string :name
      t.float :start_mya
      t.float :end_mya

      t.timestamps
    end
  end
end
