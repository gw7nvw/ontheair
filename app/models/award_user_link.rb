class AwardUserLink < ActiveRecord::Base
  belongs_to :user, class_name: "User"
  belongs_to :award, class_name: "Award"

def threshold_name
  name=""
  if threshold then 
    t=AwardThreshold.find_by(threshold: self.threshold)
    name=t.name
  end
  name
end

def generate_notification
  puts "We should generate an email to "+self.user.callsign+" for award "+self.award.name
  if self.user.is_active and self.user.email then UserMailer.award_notification(self).deliver
    self.notification_sent=true
    self.save
  end
end

def district
  if self.award_type=="district" then District.find(self.linked_id) else nil end
end

def region
  if self.award_type=="region" then Region.find(self.linked_id) else nil end
end

def publicise
  post=Post.new
  post.title="New award for "+self.user.callsign
  post.description=self.user.callsign+" has earned "+self.award.name+" award"
  if self.award_type=="threshold" then
    post.description+=" - "+threshold_name+" ("+threshold.to_s+")"
  end
  if self.award_type=="district" then
    post.description+=" - "+activity_type.capitalize+" - for district "+self.district.name
  end
  if self.award_type=="region" then
    post.description+=" - "+activity_type.capitalize+" - for region "+self.region.name
  end

  post.created_by_id=self.user.id
  post.save

  item=Item.new
  item.topic_id=AWARDS_TOPIC
  item.item_type="post"
  item.item_id=post.id
  item.save
  #if !post.do_not_publish then item.send_emails end
end
end

