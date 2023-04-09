class Post < ActiveRecord::Base

#include ActionView::Helpers::PostsHelper
include PostsHelper
include MapHelper
has_attached_file :image,
:path => ":rails_root/public/system/:attachment/:id/:basename_:style.:extension",
:url => "/system/:attachment/:id/:basename_:style.:extension"

do_not_validate_attachment_file_type :image

after_save :update_item
before_save { self.before_save_actions }

def before_save_actions
  self.add_child_codes
end

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

  def add_child_codes
    if self.asset_codes then
       self.asset_codes=self.get_all_asset_codes
    end
  end

  def get_all_asset_codes
    codes=self.asset_codes
    newcodes=codes
    codes.each do |code|
      newcodes=newcodes+Asset.child_codes_from_parent(code)
      newcodes=newcodes+VkAsset.child_codes_from_parent(code)
    end
    newcodes=newcodes.uniq
    #filter out POTA / WWFF if user does not use those schemes
    user=User.find_by(callsign: self.callsign.upcase)
    if(user and user.logs_pota==false) then newcodes=newcodes.select {|code| Asset.get_asset_type_from_code(code)!="pota park" } end
    if(user and user.logs_wwff==false) then newcodes=newcodes.select {|code| Asset.get_asset_type_from_code(code)!="wwff park" } end
    newcodes
  end

def send_to_all(debug, from, callsign, assets, freq, mode, description, topic,idate,itime,tzname)
  result=true
  messages=""
  if topic and topic.is_spot then
    #SPOT
    assets.each do |ac|
      asset_type=Asset.get_asset_type_from_code(ac)
      puts "DEBUG :"+asset_type+":"
      matched=false
      if asset_type=='pota park' or asset_type=="POTA" then
        puts "DEBUG: send "+ac+" to POTA"
        pota_response=self.send_to_pota(debug, from.callsign, callsign, ac, freq, mode, description)
        result=(result and pota_response[:result])
        messages=messages+pota_response[:messages]
        matched=true
      elsif asset_type=='SOTA' or asset_type=="summit" then
        puts "DEBUG: send "+ac+" to SOTA"
        sota_response=self.send_to_sota(debug, from.acctnumber, callsign, ac, freq, mode, description)
        result=(result and sota_response[:result])
        messages=messages+sota_response[:messages]
        matched=true
      end
      if result==false or matched==false then
        puts "DEBUG: send "+ac+" to PnP"
        pnp_response=self.send_to_pnp(debug,ac,topic,idate,itime,tzname)
        result=(result and pnp_response[:result])
        messages=messages+pnp_response[:messages]
      end
    end 
  else
    #ALERT so only send to PNP
    assets.each do |ac|
      pnp_response=send_to_pnp(debug,ac,topic,idate,itime,tzname)
      result=(result and pnp_response[:result])
      messages=messages+pnp_response[:messages]
    end
  end
  {result: result, messages: messages}
end

def send_to_pota(debug, from, callsign, a_code, freq, mode, description)
    result=true
    messages=""

    #is this a valid sota reference?
    asset_type=Asset.get_asset_type_from_code(a_code)

    if asset_type=='pota park' or asset_type=="POTA" then

      url = URI.parse('https://api.pota.app/spot')

      if debug then a_code="K-TEST" end

      http=Net::HTTP.new(url.host, url.port)
      http.use_ssl=true
      http.verify_mode=OpenSSL::SSL::VERIFY_NONE

      parts=a_code.split('-')
      if parts.count==2 then
        region=parts[0]
        subcode=parts[1]

        payloadspot = {
           'activator': callsign.upcase,
           'spotter': from.upcase,
           'frequency': ((freq.to_f)*1000).to_s,
           'reference': region.upcase+"-"+subcode,
           'mode': mode.upcase,
           'source': "Web",
           'comments': description
           }

#        if debug then
          puts "Sending SPOT to POTA"
          puts payloadspot
#        end

#        req = Net::HTTP::Get.new("#{url.path}?".concat(payloadspot.collect { |k,v| "#{k}=#{CGI::escape(v.to_s)}" }.join('&')), 'Content-Type' => 'application/json' )
        req = Net::HTTP::Post.new("#{url.path}?", 'Content-Type' => 'application/json' )
        req.body=payloadspot.to_json

        res=http.request(req)
        puts "DEBUG: POTA response"
        puts res.body
        pspots=JSON.parse(res.body)
        ourspot=pspots.find { |ps| ps["activator"]==callsign.upcase and ps["reference"]==region.upcase+"-"+subcode and ps["mode"]==mode.upcase and (ps["frequency"]).to_i == ((freq.to_f)*1000).to_i }
        if !ourspot then 
           result=false
           puts "DUBUG: spot not accepted by POTA"
           messages="Spot not accepted by POTA for: "+a_code+"; "
        end
      else
        puts "Invalid POTA code: "+a_code
        messages="Invalid POTA code: "+a_code+"; "
        result=false
      end
    else
        if debug then
          puts "Not a POTA asset: "+a_code
          messages="Not a POTA asset: "+a_code+"; "
          result=false
        end
    end
    {result: result, messages: messages}
end


def send_to_sota(debug, from, callsign, a_code, freq, mode, description)
    result=true
    messages=""

    #is this a valid sota reference?
    asset_type=Asset.get_asset_type_from_code(a_code)
    puts ":"+asset_type+":"
    if asset_type=='SOTA' or asset_type=="summit" then

      jscreds=Keycloak::Client.get_token(SOTA_USER, SOTA_PASSWORD, SOTA_CLIENT_ID, SOTA_SECRET)
      creds=JSON.parse(jscreds)
      access_token=creds["access_token"]
      id_token=creds["id_token"]

      if debug then
        url = URI.parse('https://cluster.sota.org.uk:8150/testme')
      else
        url = URI.parse('https://cluster.sota.org.uk:8150/spotme')
      end

      http=Net::HTTP.new(url.host, url.port)
      http.use_ssl=true
      http.verify_mode=OpenSSL::SSL::VERIFY_NONE

      parts=a_code.split('/')
      if parts.count==2 then
        region=parts[0]
        subcode=parts[1]

        payloadspot = {
           'To': '+64273105319',
           'MessageTime': Time.now.utc.strftime("%a %b %d %H:%M:%S %Y"),
           'From': from,
           'MessageSid': 'SMS_ZL',
           'Body': callsign+" "+region+" "+subcode+" "+freq+" "+mode+" "+description
           }

        if debug then 
          puts "Sending SPOT to SOTA"
          puts payloadspot
        end

        req = Net::HTTP::Get.new("#{url.path}?".concat(payloadspot.collect { |k,v| "#{k}=#{CGI::escape(v.to_s)}" }.join('&')), 'Content-Type' => 'application/json', 'Authorization' => "bearer "+access_token, 'id_token' => id_token, 'connection' => 'keep-alive')


        res=http.request(req)
        puts "DEBUG: SOTA response"
        puts res.body
      else
        puts "Invalid SOTA code: "+a_code
        messages="Invalid SOTA code: "+a_code+"; "
        result=false
      end
    else
        if debug then 
          puts "Not a SOTA asset: "+a_code
          messages="Not a SOTA asset: "+a_code+"; "
          result=false
        end
    end 
    {result: result, messages: messages}
end

def send_to_pnp(debug,ac,topic,idate,itime,tzname)
    result=false
    messages=""
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

        code=ac.split(']')[0]
        code=code.gsub('[','')
        pnp_class=Asset.get_pnp_class_from_code(code)
            #hack to remove once PnP updated to new codes
#            if code[0..2]=="ZLP" or code[0..2]=="ZLH" or code[0..2]=="ZLI" then 
#               aa=Asset.find_by(code: code)
#               code=aa.old_code
#            end
        if pnp_class and pnp_class!="" then
          puts "sending alert to PnP"
          params = {"actClass" => pnp_class,"actCallsign" => self.updated_by_name,"actSite" => code,"actMode" => self.mode.strip,"actFreq" => self.freq.strip,"actComments" => convert_to_text(self.description),"userID" => "ZLOTA","APIKey" => "4DDA205E08D2","alDate" => if tt then tt.strftime('%Y-%m-%d') else "" end,"alTime" => if tt then tt.strftime('%H:%M') else "" end,"optDay" => if dayflag then "1" else "0" end}
          response=send_alert_to_pnp(params,dbtext)
        end
    end
    if topic.is_spot then
        code=ac.split(']')[0]
        code=code.gsub('[','')
        pnp_class=Asset.get_pnp_class_from_code(code)
#            if code[0..2]=="ZLP" or code[0..2]=="ZLH" or code[0..2]=="ZLI" then 
#               aa=Asset.find_by(code: code)
#               if aa then code=aa.old_code end
#            end
        if pnp_class and pnp_class!="" then
          params = {"actClass" => pnp_class,"actCallsign" => (self.callsign||self.updated_by_name),"actSite" => code,"mode" => self.mode.strip,"freq" => self.freq.strip,"comments" => convert_to_text(self.description),"userID" => "ZLOTA","APIKey" => "4DDA205E08D2"}
          puts "sending spot to PnP"
          response=send_spot_to_pnp(params,dbtext)
        end
    end
    if response and response!="" then
      result=true
      debugstart=response.body.index("received")
      debugfail=response.body.index("Failure")
      if debugfail then 
        puts "DEBUG: Send to PnP recieved failed"
        result=false 
      end
      if debugstart then
        messages="PnP responsed with: "+response.body[debugstart..-1]
      end
    else
      messages="Failed to send "+ac+" to PnP. Did you specify a valid place, frequency, mode & callsign?; "
      result=false
    end

    {result: result, messages: messages}
end

end


