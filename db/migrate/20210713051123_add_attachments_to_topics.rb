# typed: false
class AddAttachmentsToTopics < ActiveRecord::Migration
  def change
    add_column :topics, :allow_attachments, :boolean
  end
end
