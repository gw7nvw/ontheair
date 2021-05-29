class Post < ActiveRecord::Base
#include ActionView::Helpers::PostsHelper
include PostsHelper

    establish_connection "qrp"
    require 'htmlentities'

def updated_by_name
  user=User.find_by_id(self.updated_by_id)
  if user then user.callsign else "" end
end

def check_hut_code
  hut_code=""
  code=self.hut[0..7]
  id=self.hut[4..7].to_i
  if code[0..3]=="ZLH/" then
   if Hut.find_by_id(id) then
     hut_code=code[0..7]
   end
  end
  hut_code
end

def check_island_code
  island_code=""
  code=self.island[0..8]
  id=self.island[4..8].to_i
  if code[0..3]=="ZLI/" then
   if Island.find_by_id(id) then
     island_code=code[0..8]
   end
  end
  island_code
end

def check_park_code
  park_code=""
  code=self.park[0..10]
  id=self.park[4..10].to_i
  if code[0..3]=="ZLP/" then
   if Park.find_by_id(id) then
     park_code=code[0..10]
   end
  end
  park_code
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
