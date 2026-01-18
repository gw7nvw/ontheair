# frozen_string_literal: true

require "base64"

# typed: false
class Item < ActiveRecord::Base
  MAX_SPOT_CONSOLIDATION_TIME = 15
  MAX_SPOT_LIFETIME = 60
  SPOT_TOPIC = 35
  after_save :after_save_actions

  def after_save_actions
    update_topic_timestamp
    create_consolidated_spot if self.post and self.topic_id==SPOT_TOPIC
  end

  def update_topic_timestamp
    if topic_id
      t = topic
      t.last_updated = Time.now
      t.save
    end
  end

  def comments
    comments = self.end_item.description if self.end_item
    comments
  end
 
  def raw_image
    if self.end_item.image_content_type
      image = File.read(self.end_item.image.path)
      image = Base64.encode64(image) if image
    end
    image
  end

  def summary
      callsign = self.end_item.callsign && !self.end_item.callsign.empty? ? self.end_item.callsign.upcase : self.end_item.updated_by_name
      if self.topic.is_spot
        if self.end_item.site then
          sites = self.end_item.site.split('; ')
        else
          sites = []
        end
        summary = callsign + ' spotted on ' + ((self.end_item.freq && !self.end_item.freq.empty?) || (self.end_item.mode && !self.end_item.mode.empty?) ? self.end_item.freq + ' - ' + self.end_item.mode : 'UNKNOWN') + ' at ' + (sites && sites.count.positive? ? sites.first + (if sites && (sites.count > 1) then ' et al.' else '' end) : 'UNKNOWN')

      elsif self.topic.is_alert
        if self.end_item.site then
          sites = self.end_item.site.split('; ')
        else
          sites = []
       end
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

  def create_consolidated_spot
     round_freq = post.freq.to_d.round(3).to_s

#    dups=ConsolidatedSpot.find_by_sql [ "select * from consolidated_spots where updated_at > '#{MAX_SPOT_CONSOLIDATION_TIME.minutes.ago.to_s}' and \"activatorCallsign\" = '#{post.callsign}' and frequency = '#{post.freq.to_s}' and mode = '#{post.mode}' order by created_at desc limit 1" ]
     puts "select * from consolidated_spots where (updated_at > '#{MAX_SPOT_CONSOLIDATION_TIME.minutes.ago.to_s}' or ('#{post.asset_codes.first}' = ANY(code) and updated_at > '#{MAX_SPOT_LIFETIME.minutes.ago.to_s}')) and \"activatorCallsign\" = '#{post.callsign}' and (frequency = '#{round_freq}' or frequency is null or frequency = '' or frequency = '0.0' or '#{round_freq}' = '' or '#{round_freq}' = '0.0') and (mode = '#{post.mode}' or mode is null or mode = '' or '#{post.mode}'='') order by created_at desc limit 1"

    dups=ConsolidatedSpot.find_by_sql [ "select * from consolidated_spots where (updated_at > '#{MAX_SPOT_CONSOLIDATION_TIME.minutes.ago.to_s}' or ('#{post.asset_codes.first}' = ANY(code) and updated_at > '#{MAX_SPOT_LIFETIME.minutes.ago.to_s}')) and \"activatorCallsign\" = '#{post.callsign}' and (frequency = '#{round_freq}' or frequency is null or frequency = '' or frequency = '0.0' or '#{round_freq}' = '' or '#{round_freq}' = '0.0') and (mode = '#{post.mode}' or mode is null or mode = '' or '#{post.mode}'='') order by created_at desc limit 1" ]

    if dups and dups.count>0 then
      cs=dups.first
    else
      cs=ConsolidatedSpot.new
      cs.activatorCallsign = post.callsign
      cs.frequency = round_freq
      cs.mode = post.mode
    end
    cs.frequency = round_freq if round_freq and round_freq != '' and round_freq.to_d != 0
    cs.mode = post.mode if post.mode and post.mode != ''
    cs.time += [self.created_at]
    cs.callsign += [post.updated_by_name]
    cs.code += post.asset_codes
    cs.code = cs.code.uniq
    cs.name += [post.site]
    cs.name = cs.name.uniq
    cs.comments += [post.updated_by_name+": "+post.description + " ("+post.created_at.strftime("%H:%M:%S")+")"]
    as = Asset.assets_from_code(cs.code.join(', '))
    types =  as.map{|a| a[:pnp_class]}
    cs.spot_type += types
    cs.spot_type = cs.spot_type.uniq
    cs.post_id += [id.to_s]

    cs.save
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
        raw_image = item.raw_image
        summary = item.summary
        subs = UserTopicLink.where(topic_id: item.topic_id)
        subs.each do |sub|
          @user = User.find_by_id(sub.user_id)
          UserMailer.subscriber_mail(item, @user).deliver if sub.mail
          @user.send_notification(summary, item.url, if @user.push_include_comments then item.comments else nil end, if @user.push_include_map then raw_image else nil end) if sub.notification
        end
      end
    #end
  end
end
