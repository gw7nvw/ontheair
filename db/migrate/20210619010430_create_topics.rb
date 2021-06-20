class CreateTopics < ActiveRecord::Migration
  def change
    create_table :topics do |t|
    t.string   "name"
    t.text     "description"
    t.integer  "owner_id"
    t.boolean  "is_public"
    t.boolean  "is_owners"
    t.datetime "last_updated"
    t.integer  "created_by_id"
    t.integer  "updated_by_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "is_members_only"
    t.boolean  "date_required"
    t.boolean  "allow_mail"
    t.boolean  "duration_required"
    t.boolean  "is_alert"
    t.boolean  "is_spot"

    end
  end
end
