class CreateBands < ActiveRecord::Migration
  def change
    create_table :bands do |t|
      t.string   "meter_band"
      t.string   "freq_band"
      t.string   "group"
      t.float   "min_frequency"
      t.float   "max_frequency"
    end
  end
end
