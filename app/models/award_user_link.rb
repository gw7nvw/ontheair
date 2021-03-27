class AwardUserLink < ActiveRecord::Base
  belongs_to :user, class_name: "User"
  belongs_to :award, class_name: "Award"

def generate_notification
  puts "We should generate an email to "+self.user.callsign+" for award "+self.award.name
  if self.user.is_active and self.user.email then UserMailer.award_notification(self).deliver
    self.notification_sent=true
    self.save
  end
end
end
