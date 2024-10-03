# typed: false
class CreateSotaRegions < ActiveRecord::Migration
  def change
    create_table :sota_regions do |t|
      t.string :dxcc
      t.string :region

      t.timestamps
    end
  end
end
