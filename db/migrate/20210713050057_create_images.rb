class CreateImages < ActiveRecord::Migration
  def change
  create_table "images", force: true do |t|
    t.string   "title"
    t.text     "description"
    t.string   "filename"
    t.string   "image_file_name"
    t.string   "image_content_type"
    t.integer  "image_file_size"
    t.datetime "image_updated_at"
    t.integer  "created_by_id"
    t.integer  "updated_by_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "post_id"
  end

  end
end
