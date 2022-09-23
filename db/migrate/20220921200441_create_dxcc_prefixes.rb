class CreateDxccPrefixes < ActiveRecord::Migration
  def change
    create_table :dxcc_prefixes do |t|
      t.string :name
      t.string :prefix
      t.string :itu_zone
      t.string :cq_zone
      t.string :continent_code
    end
  end
end
