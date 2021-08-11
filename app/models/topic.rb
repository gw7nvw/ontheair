class Topic < ActiveRecord::Base
def items
  items=Item.find_by_sql [ "select * from items where topic_id="+self.id.to_s+" order by updated_at desc" ]
end

def owner
  owner=User.find_by_id(self.owner_id)
end

def parent_topic
  item=Item.find_by_sql [" select * from items where item_type='topic' and item_id="+self.id.to_s ]
  if item and item.count>0 then
    topic=Topic.find_by_id(item.first.topic_id)
  end
  topic
end

def owner_callsign
  callsign=""
  if self.owner_id and self.owner then callsign =self.owner.callsign end
  callsign
end

def subscribed(user)
  subs=UserTopicLink.find_by_sql [ "select * from user_topic_links where user_id = "+user.id.to_s+" and topic_id = "+self.id.to_s ]
  if subs and subs.count>0 then true else false end
end

def url
  url=[self.id, self.name.parameterize].join('-')
end
end
