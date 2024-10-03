# typed: false
class CreateVkAssets < ActiveRecord::Migration
  def change
    create_table :vk_assets do |t|
      t.string :award
      t.string :wwff_code
      t.string :pota_code
      t.string :shire_code
      t.string :state
      t.string :region
      t.string :district
      t.string :code
      t.string :name
      t.string :site_type
      t.float :latitude
      t.float :longitude
      t.spatial :location, limit: {:srid=>4326, :type=>"point"}

      t.timestamps
    end
  end
end
