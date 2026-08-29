# frozen_string_literal: true

# typed: false
class Image < ActiveRecord::Base
  has_attached_file :image,
                    path: ':rails_root/public/system/:attachment/:id/:basename_:style.:extension',
                    url: '/system/:attachment/:id/:basename_:style.:extension',
                    styles: {
                      thumb: ['102x76#',  :jpg, quality: 70],
                      original: ['1024>', :jpg, quality: 50]
                    },
                    convert_options: {
                      thumb: '-set colorspace sRGB -strip',
                      original: '-set colorspace sRGB'
                    }

  validates_attachment :image,
                       presence: true,
                       size: { in: 0..10.megabytes },
                       content_type: { content_type: /^image\/(jpeg|png)$/ }
  after_save :update_item

  attr_accessor :asset_codes

  def update_item
    i = item
    if i
      i.touch
      i.save
    end
  end

  def updated_by_name
    user = User.find_by_id(updated_by_id)
    user ? user.callsign : ''
  end

  def topic_name
    topic = Topic.find_by_id(topic_id)
    topic ? topic.name : ''
  end

  def topic
    Topic.find_by_id(topic_id)
  end

  def topic_id
    topic = nil
    item = self.item
    topic = item.topic_id if item
    topic
  end

  def item
    item = nil
    items = Item.find_by_sql ["select * from items where item_type='image' and item_id=" + id.to_s]
    item = items.first if items
    item
  end

  def get_asset_codes
    acs = []
    links = AssetPhotoLink.where(photo_id: id)
    links.each do |link|
      acs.push(link.asset_code)
    end
    acs.join(',')
  end

  def links
    AssetPhotoLink.where(photo_id: id)
  end
end
