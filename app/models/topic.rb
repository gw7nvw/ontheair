class Topic < ActiveRecord::Base

    establish_connection "qrp"
def url
  url=[self.id, self.name.parameterize].join('-')
end

def subscribed(user)
  subs=UserTopicLink.find_by_sql [ "select * from user_topic_links where user_id = "+user.id.to_s+" and topic_id = "+self.id.to_s ]
  if subs and subs.count>0 then true else false end
end

end


