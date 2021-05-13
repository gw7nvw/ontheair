class CreateAssetWebLinks < ActiveRecord::Migration
  def change
    create_table :asset_web_links do |t|
      t.string :asset_code
      t.string :url
      t.string :link_class

      t.timestamps
    end
  end
end
