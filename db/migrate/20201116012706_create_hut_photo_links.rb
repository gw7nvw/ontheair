class CreateHutPhotoLinks < ActiveRecord::Migration
  def change
    create_table :hut_photo_links do |t|
      t.integer :hut_id
      t.string :url

      t.timestamps
    end
  end
end
