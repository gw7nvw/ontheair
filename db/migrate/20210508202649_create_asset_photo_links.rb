# typed: false
class CreateAssetPhotoLinks < ActiveRecord::Migration
  def change
    create_table :asset_photo_links do |t|
         t.string :asset_code
         t.string :link_url
      t.timestamps
    end
  end
end
