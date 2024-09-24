class CreateGeologicalPeriods < ActiveRecord::Migration
  def change
    create_table :geological_periods do |t|
      t.string :name
      t.float :start_mya
      t.float :end_mya
      t.timestamps
    end
  end
end
