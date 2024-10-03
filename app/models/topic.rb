# frozen_string_literal: true

# typed: false
class Topic < ActiveRecord::Base
  def items
    Item.find_by_sql ['select * from items where topic_id=' + id.to_s + ' order by updated_at desc']
  end

  def owner
    User.find_by_id(owner_id)
  end

  def parent_topic
    item = Item.find_by_sql [" select * from items where item_type='topic' and item_id=" + id.to_s]
    topic = Topic.find_by_id(item.first.topic_id) if item && item.count.positive?
    topic
  end

  def owner_callsign
    callsign = ''
    callsign = owner.callsign if owner_id && owner
    callsign
  end

  def subscribed(user)
    subs = UserTopicLink.find_by_sql ['select * from user_topic_links where user_id = ' + user.id.to_s + ' and topic_id = ' + id.to_s]
    subs && subs.count.positive? ? true : false
  end

  def url
    [id, name.parameterize].join('-')
  end
end
