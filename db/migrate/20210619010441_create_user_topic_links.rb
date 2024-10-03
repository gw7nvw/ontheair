# typed: false
class CreateUserTopicLinks < ActiveRecord::Migration
  def change
    create_table :user_topic_links do |t|
    t.integer  "user_id"
    t.integer  "topic_id"
    t.boolean  "mail"
    t.datetime "created_at"
    t.datetime "updated_at"

    end
  end
end
