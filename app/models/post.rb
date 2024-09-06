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
  self.replace_master_codes
  self.add_containing_codes
  #again to vet child codes added
  self.replace_master_codes
  if self.callsign then self.callsign=self.callsign.upcase end
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
    if self.asset_codes then asset_names=self.asset_codes.map{|ac| asset=Asset.assets_from_code(ac).first; if asset then "["+asset[:code]+"] "+asset[:name] else "" end} else asset_names=[] end
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

  def replace_master_codes
    newcodes=[]
    self.asset_codes.each do |code|
      a=Asset.find_by(code: code)
      if !a then  a=VkAsset.find_by(code: code) end
      if !a and (!(self.description||"").include?("Unknown location: "+code)) then self.description=(self.description||"")+"; Unknown location: "+code end
      if a and a.is_active==false
        if a.master_code then 
          code=a.master_code
        end
      end
      newcodes+=[code]
    end 
    self.asset_codes=newcodes.uniq
  end

  def add_containing_codes
    if !self.do_not_lookup==true then
      if self.asset_codes then
       self.asset_codes=self.get_all_asset_codes
      end
    end
  end

  def get_all_asset_codes
    codes=self.asset_codes
    newcodes=codes
    codes.each do |code|
      newcodes=newcodes+Asset.containing_codes_from_parent(code)
      newcodes=newcodes+VkAsset.containing_codes_from_parent(code)
    end
    newcodes=newcodes.uniq
    #filter out POTA / WWFF if user does not use those schemes
    if self.callsign then user=User.find_by(callsign: self.callsign.upcase) end
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
      elsif asset_type=='HEMA' or asset_type=="hump" then
        puts "DEBUG: send "+ac+" to HEMA"
        hema_response=Post.send_to_hema(debug, from.acctnumber, callsign, ac, freq, mode, description)
        result=(result and hema_response[:result])
        messages=messages+hema_response[:messages]
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
        begin
          res=http.request(req)
          puts "DEBUG: POTA response"
          puts res.body.encode('UTF-8', invalid: :replace, undef: :replace, replace: '?')
          pspots=JSON.parse(res.body)
        rescue
          puts "Send to POTA failed"
          result=false
          messages="Failed to contact POTA server"
        else
          ourspot=pspots.find { |ps| ps["activator"]==callsign.upcase and ps["reference"]==region.upcase+"-"+subcode and ps["mode"]==mode.upcase and (ps["frequency"]).to_i == ((freq.to_f)*1000).to_i }
          if !ourspot then 
             result=false
             puts "DUBUG: spot not accepted by POTA"
             messages="Spot not accepted by POTA for: "+a_code+"; "
          end
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

def self.send_to_hema(debug, from, callsign, a_code, freq, mode, description)
  result=false
  messages=""
  asset=Asset.find_by(code: a_code)
  asset_type=Asset.get_asset_type_from_code(a_code)
  if asset and (asset_type=="hump" or asset_type=="HEMA") then
    modes={"AM" =>1,"FM" => 2,"CW" => 3,"SSB" => 4, "USB" => 4, "LSB" => 4, "DATA" => 7,"OTHER" => 9}
    mode=mode.upcase
    modekey=modes[mode]
    if !modekey then modekey=7 end
    puts modekey, mode
   
    params = '?number='+asset.old_code+'&frequency='+freq.to_s+'&callsign='+callsign+'&modeKey='+modekey.to_s+'&seededPair=2C1CD544EC774B90884839AC4DECEB9F2E2638EABBFF4CEB8B4085AE1CD26283'

    puts "sending spot to HEMA"
    uri = URI('http://www.hema.org.uk/submitMobileSpot.jsp')
    puts "DEBUG: http://www.hema.org.uk/submitMobileSpot.jsp"+params
    http=Net::HTTP.new(uri.host, uri.port)
    req = Net::HTTP::Get.new(uri.path+params)
    begin
      response = http.request(req)
      if response then result=true end
    rescue
      messages="Failed to contact HEMA server"
    else
      puts response
      puts response.body
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


        begin
          res=http.request(req)
        rescue
          puts "Send to SOTA failed"
          result=false
          messages="Failed to contact SOTA server"
        else
          puts "DEBUG: SOTA response"
          puts res.body
        end
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
          uri = URI('http://parksnpeaks.org/api/ALERT'+dbtext)
          http=Net::HTTP.new(uri.host, uri.port)
          req = Net::HTTP::Post.new(uri.path, 'Content-Type' => 'application/json')
          req.body = params.to_json
          begin
            response = http.request(req)
          rescue
            messages="Failed to contact PnP server"
          else
            puts response
            puts response.body
          end
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
          uri = URI('http://parksnpeaks.org/api/SPOT'+dbtext)
puts "DEBUG: http://parksnpeaks.org/api/SPOT"+dbtext
          http=Net::HTTP.new(uri.host, uri.port)
          req = Net::HTTP::Post.new(uri.path, 'Content-Type' => 'application/json')
          req.body = params.to_json
          begin
            response = http.request(req)
          rescue
            messages="Failed to contact PnP server"
          else
            puts response
            puts response.body
          end
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
      if !messages or messages=="" then messages="Failed to send "+ac+" to PnP. Did you specify a valid place, frequency, mode & callsign?; " end
      result=false
    end

    {result: result, messages: messages}
end

def get_most_accurate_location
   location=nil
   loc_point=false
   accuracy=999999999999
   self.asset_codes.each do |code|
     puts "DEBUG: assessing code1 #{code}"
     assets=Asset.find_by_sql [ " select id, asset_type, location, area from assets where code='#{code}' limit 1" ]
     if assets then asset=assets.first else asset=nil end
     if asset then
       if asset.type.has_boundary then
         if loc_point==false and asset.area and asset.area<accuracy then
           location=asset.location
           accuracy=asset.area
           loc_point=false
           puts "DEBUG: Assigning polygon locn"
         end
       else
         if loc_point==true then
           puts "Multiple POINT locations found for post #{self.id.to_s}"
         end
         location=asset.location
         loc_point=true
         puts "DEBUG: Assigning point locn"
       end
     end
   end
   location
end

end


