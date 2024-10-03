# typed: false
class CreatePosts < ActiveRecord::Migration
  def change
    create_table :posts do |t|
    t.string   "title"
    t.text     "description"
    t.integer  "created_by_id"
    t.integer  "updated_by_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "filename"
    t.string   "image_file_name"
    t.string   "image_content_type"
    t.integer  "image_file_size"
    t.datetime "image_updated_at"
    t.boolean  "do_not_publish"
    t.datetime "referenced_datetime"
    t.datetime "referenced_date"
    t.datetime "referenced_time"
    t.integer  "duration"
    t.string   "site"
    t.string   "code"
    t.string   "mode"
    t.string   "freq"
    t.boolean  "is_hut"
    t.boolean  "is_park"
    t.boolean  "is_island"
    t.boolean  "is_summit"
    t.string   "hut"
    t.string   "park"
    t.string   "island"
    t.string   "summit"
    t.string   "callsign"
    t.string   "asset_codes",         default: [], array: true
    end
  end
end
