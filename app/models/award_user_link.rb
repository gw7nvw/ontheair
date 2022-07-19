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
end
