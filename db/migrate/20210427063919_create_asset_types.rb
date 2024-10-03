# typed: false
class CreateAssetTypes < ActiveRecord::Migration
  def change
    create_table :asset_types do |t|
      t.string :name
      t.string :table_name
      t.boolean :has_location
      t.boolean :has_boundary
      t.string :index_name
      
      t.timestamps
    end
  end
end
