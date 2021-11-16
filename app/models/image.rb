class Image < ActiveRecord::Base
has_attached_file :image,
:path => ":rails_root/public/system/:attachment/:id/:basename_:style.:extension",
:url => "/system/:attachment/:id/:basename_:style.:extension",
:styles => {
  :thumb    => ['102x76#',  :jpg, :quality => 70],
  :original    => ['1024>', :jpg, :quality => 50],
},
:convert_options => {
  :thumb    => '-set colorspace sRGB -strip',
  :original    => '-set colorspace sRGB',
}

validates_attachment :image,
    :presence => true,
    :size => { :in => 0..10.megabytes },
    :content_type => { :content_type => /^image\/(jpeg|png)$/ }
after_save :update_item

attr_accessor :asset_codes

def update_item
  i=self.item
  if i then
    i.touch
    i.save
  end
end


def updated_by_name
  user=User.find_by_id(self.updated_by_id)
  if user then user.callsign else "" end
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
  items=Item.find_by_sql [ "select * from items where item_type='image' and item_id="+self.id.to_s ]
  if items then
     item=items.first
  end
  item
end

def get_asset_codes
  acs=[]
  links=AssetPhotoLink.where(:photo_id => self.id)
  links.each do |link|
    acs.push(link.asset_code)
  end
  acs.join(',') 
end

def links
  links=AssetPhotoLink.where(:photo_id => self.id)
end
end
