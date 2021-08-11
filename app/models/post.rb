class Post < ActiveRecord::Base
#include ActionView::Helpers::PostsHelper
include PostsHelper
include MapHelper
has_attached_file :image,
:path => ":rails_root/public/system/:attachment/:id/:basename_:style.:extension",
:url => "/system/:attachment/:id/:basename_:style.:extension"

do_not_validate_attachment_file_type :image

after_save :update_item

def update_item
  i=self.item
  if i then
    i.touch
    i.save
  end
end

attr_accessor :x1
attr_accessor :y1
attr_accessor :location1

#    establish_connection "qrp"
    require 'htmlentities'

def updated_by_name
  user=User.find_by_id(self.updated_by_id)
  if user then user.callsign else "" end
end

  def assets
    if self.asset_codes then Asset.where(code: self.asset_codes) else [] end
  end


  def asset_names
    asset_names=self.assets.map{|asset| asset.name}
    if !asset_names then asset_names="" end
    asset_names
  end

  def asset_code_names
    if self.asset_codes then asset_names=self.asset_codes.map{|ac| asset=Asset.assets_from_code(ac).first; "["+asset[:code]+"] "+asset[:name]} else asset_names=[] end
    if !asset_names then asset_names=[] end
    asset_names
  end

def add_map_image
  location=nil
  if self.asset_codes then
    point_loc=nil
    poly_loc=nil
    self.asset_codes.each do |ac|
      a=Asset.find_by(code: ac)
      if a and a.type.has_boundary then 
        if a.location then poly_loc={x: a.x, y: a.y} end
      else
        if a and a.location then point_loc={x: a.x, y: a.y} end
      end
    end
    if point_loc then location=point_loc else location=poly_loc end
  end
 
  if location then
    filename=get_map(location[:x], location[:y], 9, "map_"+self.id.to_s) 
#    filename=get_map_zoomed(location[:x], location[:y], 7,15, "map_"+self.id.to_s) 
    begin
      self.image=File.open(filename,'rb')
      self.save
      system("rm #{filename}")
    rescue
      puts "SAVEMAP: ERROR"
    end
  end
end

def images
  if self.id then images=Image.where(post_id: self.id) else [] end
end

def files
#  if self.id then ufs=Uploadedfile.where(post_id: self.id) else [] end
  []
end

def is_file
#    if self.image_content_type and self.image_content_type[0..10]=='application' then true else false end
  false
end


def is_image
  if self.image_content_type and self.image_content_type[0..4]=='image' then true else false end
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
  items=Item.find_by_sql [ "select * from items where item_type='post' and item_id="+self.id.to_s ]
  if items then
     item=items.first
  end
  item
end

def send_to_pnp(debug,topic,idate,itime,tzname)
    res=""
        if debug then dbtext="/DEBUG" else dbtext="" end
        puts "DEBUG status: "+dbtext 
        if topic and topic.is_alert then
            if itime and itime.length>0 then dayflag=false else dayflag=true end
            dt=(idate||"")+" "+(itime||"")
            if dt and dt.length>1 then
              if dayflag then
                tt=dt.in_time_zone("UTC")
              else
                if tzname=="UTC" then
                  tt=dt.in_time_zone("UTC")
                else
                  tt=dt.in_time_zone("Pacific/Auckland")
                  tt=tt.in_time_zone("UTC")
                end
              end
            end

            puts "sending alert(s) to PnP"

            self.asset_codes.each do |ac|
              code=ac.split(']')[0]
              code=code.gsub('[','')
              pnp_class=Asset.get_pnp_class_from_code(code)
              #hack to remove once PnP updated to new codes
#              if code[0..2]=="ZLP" or code[0..2]=="ZLH" or code[0..2]=="ZLI" then 
#                 aa=Asset.find_by(code: code)
#                 code=aa.old_code
#              end
              if pnp_class and pnp_class!="" then
                puts "sending alert to PnP"
                params = {"actClass" => pnp_class,"actCallsign" => self.updated_by_name,"actSite" => code,"actMode" => self.mode,"actFreq" => self.freq,"actComments" => convert_to_text(self.description),"userID" => "ZLOTA","APIKey" => "4DDA205E08D2","alDate" => if tt then tt.strftime('%Y-%m-%d') else "" end,"alTime" => if tt then tt.strftime('%H:%M') else "" end,"optDay" => if dayflag then "1" else "0" end}
                res=send_alert_to_pnp(params,dbtext)
              end
            end
        end
        if topic.is_spot then
            self.asset_codes.each do |ac|
              code=ac.split(']')[0]
              code=code.gsub('[','')
              pnp_class=Asset.get_pnp_class_from_code(code)
#              if code[0..2]=="ZLP" or code[0..2]=="ZLH" or code[0..2]=="ZLI" then 
#                 aa=Asset.find_by(code: code)
#                 if aa then code=aa.old_code end
#              end
              if pnp_class and pnp_class!="" then
                params = {"actClass" => pnp_class,"actCallsign" => (self.callsign||self.updated_by_name),"actSite" => code,"mode" => self.mode,"freq" => self.freq,"comments" => convert_to_text(self.description),"userID" => "ZLOTA","APIKey" => "4DDA205E08D2"}
                puts "sending spot to PnP"
                res=send_spot_to_pnp(params,dbtext)
              end
            end
        end
   res
end


end

