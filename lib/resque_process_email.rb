class InvalidReplyUser    < StandardError ; end

class EmailReceive
  @queue = :ontheair
  SPOT_TOPIC_ID=35
  ALERT_TOPIC_ID=1
#  SPOT_TOPIC_ID=32
#  ALERT_TOPIC_ID=32

  def self.perform(from, to, subject, body, attachment)
     via=""
     posttype=nil
     if to[0..3].upcase=="SPOT" then
       puts "DEBUG: SPOT" 
       posttype="spot"
     end 
     if to[0..4].upcase=="ALERT" then
       puts "DEBUG: ALERT" 
       posttype="alert"
     end 
     if to[0..6].upcase=="ZL-SOTA" then
       puts "DEBUG: ZL-SOTA"
       posttype="zlsota"
     end
     if to[0..3].upcase=="LOGS" then
       puts "DEBUG: LOGS"
       posttype="logs"
     end
    params = {
      :body     => body,
      :to       => to,
      :subject  => subject,
      :from     => from
    }
    puts "DEBUG body: "+body
    puts "DEBUG subject: "+subject
    puts "DEBUG from: "+from
    puts "DEBUG to: "+to

    # forward mail to zl-sota
    if posttype=="zlsota" then
       UserMailer.zlsota_mail(body.gsub(/https.*$/,'{link removed}'), subject).deliver
    #upload a log
    elsif posttype=="logs" then
      username=nil
      pin=nil
      if subject["ZLOTA"] then
        puts "DEBUG: Valid subject"
        creds=subject.split("ZLOTA")
        if creds and creds.count>0 then 
          username=creds[1].split(":")[1]
          pin=creds[1].split(":")[2]
          puts "DEBUG: username: "+username
          puts "DEBUG: pin: "+pin
        end
      end
      #if username and pin and api_authenticate(username, pin) then
      if self.api_authenticate(username, pin) then
         puts "DEBUG: Authenticated"
         res={success: true, message: ''}
         logs=Log.import(attachment, nil)
	 puts "DEBUG: Imported"
         if logs[:success]==false then
            res={success: false, message: logs[:errors].join(", ")}
         end
         if logs[:success]==true and logs[:errors] and logs[:errors].count>0  then
            res={success: true, message: "Warnings: "+logs[:errors].join(", ")}
         end
      else
         res={success: false, message: 'Login failed using supplied credentials'}
      end
      puts "Result: "+res[:message]
      if res[:success]==false or res[:message]!="" then
        #reply with error (swapping to and from)
        UserMailer.free_form_mail(from, to, "Re: "+subject, res[:message]).deliver
      end

    else 
     #check for correct format
     if body["inr.ch"] then
      via="InReach"
      msg=body.split('inr.ch')[0]
      msgs=msg.split(' ') 
      sub_callsign=msgs[0].upcase
      passkey=msgs[1].upcase
      user=User.find_by(callsign: sub_callsign)
      if !user then puts "Unknown callsign: "+sub_callsign; return(false) end

      #should check a password here
      if !user.pin or passkey[0..3]!=user.pin[0..3] then puts "PIN does not match";return(false) end
     elsif subject["SMSForwarder"] then
      via="SMS"
      puts "DEBUG SMS"
      msg="SMS "+body
      puts "DEBUG body: "+body
      msgs=msg.split(' ') 
      passkey=nil
      acctnumber=subject.split(':')[1]
      puts "DEBUG subject: "+subject
      puts "DEBUG from number: "+acctnumber
      user=User.find_by(acctnumber: acctnumber.strip.gsub(" ",""))
     end
     if user then
      callsign=msgs[2].upcase
      if callsign=="!" then callsign=sub_callsign end
      asset_code=msgs[3].upcase
      freq=msgs[4]
      mode=msgs[5].upcase
      if posttype=="spot" then
        comments=msgs[6..-1].join(' ')
        al_date=Time.now.in_time_zone("UTC").strftime('%Y-%m-%d')
        al_time=Time.now.in_time_zone("UTC").strftime('%H:%M')
      else
        al_date=msgs[6]
        al_time=msgs[7]
        comments=msgs[8..-1].join(' ')
      end
 

      @post=Post.new
      #fill in details

      #check asset
      assets=Asset.assets_from_code(asset_code)
     # if !assets or assets.count==0 or assets.first[:code]==nil then puts "Asset not known:"+asset_code ;return(false) end
      if !assets or assets.count==0 or assets.first[:code]==nil then 
         puts "Asset not known:"+asset_code+" ... trying to continue"
         a_code=""
         a_name="Unrecognised location: "+asset_code
         a_ext=false
      else
         a_code=assets.first[:code]
         a_name=assets.first[:name]
         a_ext=assets.first[:external]
      end
      @post.mode=mode.upcase
      @post.callsign=callsign
      @post.freq=freq 
      if a_code!="" then @post.asset_codes=[a_code] else @post.asset_codes=[] end
      @post.created_by_id=user.id 
      @post.updated_by_id=user.id 
      @post.description=comments+" (via "+via+")"
      @post.referenced_time=al_time
      @post.referenced_date=al_date
      @post.updated_at=Time.now
      if comments.upcase["DEBUG"] or comments.upcase["TEST"] then debug=true else debug=false end  
     puts "DEBUG: assets - "+a_name
      if posttype=="spot" then
        topic_id=SPOT_TOPIC_ID
        @post.title="SPOT: "+callsign+" spotted portable at "+a_name+"["+a_code+"] on "+freq+"/"+mode+" at "+Time.now.in_time_zone("Pacific/Auckland").strftime('%Y-%m-%d %H:%M')+"NZ"
      else
        topic_id=ALERT_TOPIC_ID
        @post.title="ALERT: "+callsign+" going portable to "+a_name+"["+a_code+"] on "+freq+"/"+mode+" at "+al_date+" "+al_time+" UTC"
      end
      if a_ext==false then
        res=@post.save

        item=Item.new
        item.topic_id=topic_id
        item.item_type="post"
        item.item_id=@post.id
        item.save
        if debug==false then item.send_emails end
      end
      @topic=Topic.find_by_id(topic_id)
      res=@post.send_to_pnp(debug,@topic,al_date,al_time,'UTC')
     end
    end
  end

def self.api_authenticate(username, pin)
  puts "DEBUG: authenticating"
  valid=false
  if username and pin then
    puts "DEBUG: comparing username"
    user=User.find_by(callsign: username.upcase)
    puts "DEBUG: comparing pin"
    if user and user.pin.upcase==pin.upcase then
       puts "DEBUG: valid pin"
       valid=true
    else
       #authenticate via PnP 
       #if not a local user, or is a local user and have allowed PnP logins
       #if !user or (user and user.allow_pnp_login==true) then
       if (user and user.allow_pnp_login==true) then
         params={"actClass"=>"WWFF", "actCallsign"=>"test", "actSite"=>"test", "mode"=>"SSB", "freq"=>"7.095", "comments"=>"Test", "userID"=>username, "APIKey"=>pin}
         res=send_spot_to_pnp(params,'/DEBUG')
         if res.body.match('Success') then
           valid=true
           puts "AUTH: SUCCESS authenticated via PnP"
         else
           puts "AUTH: FAILED authentication via PnP"
         end
       end
    end
  end
  valid
end

end

