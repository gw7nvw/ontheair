# typed: false
class AddImageIdToAssetPhotoLink < ActiveRecord::Migration
  def change
    add_column :asset_photo_links, :photo_id, :integer
  end
end
