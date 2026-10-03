# typed: false
class AddAttachmentsToTopics < ActiveRecord::Migration[5.0]
  def change
    add_column :topics, :allow_attachments, :boolean
  end
end
