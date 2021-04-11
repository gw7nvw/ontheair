class Post < ActiveRecord::Base

    establish_connection "qrp"

def updated_by_name
  user=User.find_by_id(self.updated_by_id)
  if user then user.callsign else "" end
end

def check_hut_code
  hut_code=""
  code=self.hut[0..7]
  id=self.hut[4..7].to_i
  if code[0..3]=="ZLH/" then
   if Hut.find_by_id(id) then
     hut_code=code[0..7]
   end
  end
  hut_code
end

def check_island_code
  island_code=""
  code=self.island[0..8]
  id=self.island[4..8].to_i
  if code[0..3]=="ZLI/" then
   if Island.find_by_id(id) then
     island_code=code[0..8]
   end
  end
  island_code
end

def check_park_code
  park_code=""
  code=self.park[0..10]
  id=self.park[4..10].to_i
  if code[0..3]=="ZLP/" then
   if Park.find_by_id(id) then
     park_code=code[0..10]
   end
  end
  park_code
end

def topic_name
   topic=Topic.find_by_id(topic_id())
   if topic then topic.name else "" end
end

def topic
   topic=Topic.find_by_id(topic_id())
end

def topic_id
  topic=nil
  item=self.item
  if item then
     topic=item.topic_id
  end
  topic
end

def item
  item=nil
  items=Item.find_by_sql [ "select * from items where item_type='post' and item_id="+self.id.to_s ]
  if items then
     item=items.first
  end
  item
end

end


