# frozen_string_literal: true

# typed: false
class AwardUserLink < ActiveRecord::Base
  belongs_to :user, class_name: 'User'
  belongs_to :award, class_name: 'Award'

  def threshold_name
    name = ''
    if threshold
      t = AwardThreshold.find_by(threshold: threshold)
      name = t.name
    end
    name
  end

  def generate_notification
    puts 'We should generate an email to ' + user.callsign + ' for award ' + award.name
    if user.is_active && user.email then UserMailer.award_notification(self).deliver
                                         self.notification_sent = true
                                         save
    end
  end

  def district
    District.find(linked_id) if award_type == 'district'
  end

  def region
    Region.find(linked_id) if award_type == 'region'
  end

  def publicise
    if user.activated
      post = Post.new
      post.title = 'New award for ' + user.callsign
      post.description = user.callsign + ' has earned ' + award.name + ' award'
      if award_type == 'threshold'
        post.description += ' - ' + threshold_name + ' (' + threshold.to_s + ')'
      end
      if award_type == 'district'
        post.description += ' - ' + activity_type.capitalize + ' - for district ' + district.name
      end
      if award_type == 'region'
        post.description += ' - ' + activity_type.capitalize + ' - for region ' + region.name
      end

      post.created_by_id = user.id
      post.save

      item = Item.new
      item.topic_id = AWARDS_TOPIC
      item.item_type = 'post'
      item.item_id = post.id
      item.save
      # if !post.do_not_publish then item.send_emails end
    end
  end
end
