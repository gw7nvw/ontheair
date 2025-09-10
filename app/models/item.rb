# frozen_string_literal: true

# typed: false
class Item < ActiveRecord::Base
  after_save :update_topic_timestamp

  def update_topic_timestamp
    if topic_id
      t = topic
      t.last_updated = Time.now
      t.save
    end
  end

  def summary
      callsign = self.end_item.callsign && !self.end_item.callsign.empty? ? self.end_item.callsign.upcase : self.end_item.updated_by_name
      if self.topic.is_spot
        sites = self.end_item.site.split('; ')
        summary = callsign + ' spotted on ' + ((self.end_item.freq && !self.end_item.freq.empty?) || (self.end_item.mode && !self.end_item.mode.empty?) ? self.end_item.freq + ' - ' + self.end_item.mode : 'UNKNOWN') + ' at ' + (sites && sites.count.positive? ? sites.first + (if sites && (sites.count > 1) then ' et al.' else '' end) : 'UNKNOWN')

      elsif self.topic.is_alert
        sites = self.end_item.site.split('; ')
        summary = callsign + ' alerted for ' + (self.end_item.referenced_date ? self.end_item.referenced_date.strftime('%Y-%m-%d') : '') + ' ' + (self.end_item.referenced_time ? self.end_item.referenced_time.strftime('%H:%M (UTC)') : '') + ' at ' + (sites && sites.count.positive? ? sites.first + (if sites && (sites.count > 1) then ' et al.' else '' end) : 'UNKNOWN')
      else
        summary = 'ontheair.nz: New post from ' + self.end_item.updated_by_name + ' in ' + self.topic.name
      end

  end

  def url
    "https://ontheair.nz/topics/#{self.topic_id}#post#{self.id}"
  end

  def subtopic
    topic = (Topic.find_by_id(item_id) if item_type == 'topic')
    topic
  end

  def file
    file = (Uploadedfile.find_by_id(item_id) if item_type == 'file')
    file
  end

  def image
    image = (Image.find_by_id(item_id) if item_type == 'image')
    image
  end

  def post
    post = (Post.find_by_id(item_id) if item_type == 'post')
    post
  end

  def topic
    Topic.find_by_id(topic_id)
  end

  def end_item_path
    '/topics/' + topic_id.to_s if topic_id
  end

  def end_item
    enditem = nil
    if item_type == 'file'
      enditem = Uploadedfile.find_by_id(item_id)
    elsif item_type == 'image'
      enditem = Image.find_by_id(item_id)
    elsif item_type == 'post'
      enditem = Post.find_by_id(item_id)
    elsif item_type == 'topic'
      enditem = Topic.find_by_id(item_id)
    end
    enditem
  end

  #Schedule delayed sending of emails
  def send_emails
    Resque.enqueue(SendEmails, self.id)
  end

  # Sends email
  def self.send_emails_now(itemid)
    item=Item.find(itemid)
    if item and item.topic_id
     # if ENV['RAILS_ENV'] == 'production'
        subs = UserTopicLink.where(topic_id: item.topic_id)
        subs.each do |sub|
          @user = User.find_by_id(sub.user_id)
          UserMailer.subscriber_mail(item, @user).deliver if sub.mail
          @user.send_notification(item.summary, item.url) if sub.notification
        end
      end
    #end
  end
end
