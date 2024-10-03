# typed: false
class CreateItems < ActiveRecord::Migration
  def change
    create_table :items do |t|
    t.integer  "topic_id"
    t.string   "item_type"
    t.integer  "item_id"
    t.integer  "created_by_id"
    t.integer  "updated_by_id"
    t.datetime "created_at"
    t.datetime "updated_at"

    end
  end
end
