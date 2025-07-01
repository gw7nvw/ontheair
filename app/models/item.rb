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
      if ENV['RAILS_ENV'] == 'production'
        subs = UserTopicLink.where(topic_id: item.topic_id)
        subs.each do |sub|
          @user = User.find_by_id(sub.user_id)
          UserMailer.subscriber_mail(item, @user).deliver
        end
      end
    end
  end
end
