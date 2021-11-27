class InvalidReplyUser    < StandardError ; end

class EmailReceive
  @queue = :ontheair
  SPOT_TOPIC_ID=35
  ALERT_TOPIC_ID=1
#  SPOT_TOPIC_ID=32
#  ALERT_TOPIC_ID=32

  def self.perform(from, to, subject, body)
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
    params = {
      :body     => body,
      :to       => to,
      :subject  => subject,
      :from     => from
    }
    puts "DEBUG body: "+body
    puts "DEBUG from: "+from
    puts "DEBUG to: "+to

    # forward mail to zl-sota
    if posttype=="zlsota" then
       UserMailer.zlsota_mail(body.gsub(/https.*$/,'{link removed}'), subject).deliver
    else 
     #check for correct format
     if body["inr.ch"] then
      msg=body.split('inr.ch')[0]
      msgs=msg.split(' ') 
      sub_callsign=msgs[0].upcase
      passkey=msgs[1].upcase
      callsign=msgs[2].upcase
      if callsign=="!" then callsign=sub_callsign end
      asset_code=msgs[3].upcase
      freq=msgs[4]
      mode=msgs[5].upcase
      if posttype=="spot" then
        comments=msgs[6..-1].join(' ')
        al_date=Time.now.in_time_zone("Pacific/Auckland").strftime('%Y-%m-%d')
        al_time=Time.now.in_time_zone("Pacific/Auckland").strftime('%H:%M')
      else
        al_date=msgs[6]
        al_time=msgs[7]
        comments=msgs[8..-1].join(' ')
      end
 
      user=User.find_by(callsign: sub_callsign)
      if !user then puts "Unknown callsign: "+sub_callsign; return(false) end

      #should check a password here
      if !user.pin or passkey[0..3]!=user.pin[0..3] then puts "PIN does not match";return(false) end

      @post=Post.new
      #fill in details

      #check asset
      assets=Asset.assets_from_code(asset_code)
      if !assets or assets.count==0 or assets.first[:code]==nil then puts "Asset not known:"+asset_code ;return(false) end
      @post.mode=mode.upcase
      @post.freq=freq 
      @post.asset_codes=[assets.first[:code]]
      @post.created_by_id=user.id 
      @post.updated_by_id=user.id 
      @post.description=comments+" (via InReach)"
      @post.referenced_time=al_time
      @post.referenced_date=al_date
      @post.updated_at=Time.now
      if comments[0..4].upcase=="DEBUG" or comments[0..3].upcase=="TEST" then debug=true else debug=false end  
     puts "DEBUG: assets - "+assets.first[:name]
      if posttype=="spot" then
        topic_id=SPOT_TOPIC_ID
        @post.title="SPOT: "+callsign+" spotted portable at "+assets.first[:name]+"["+assets.first[:code]+"] on "+freq+"/"+mode+" at "+Time.now.in_time_zone("Pacific/Auckland").strftime('%Y-%m-%d %H:%M')+"NZ"
      else
        topic_id=ALERT_TOPIC_ID
        @post.title="ALERT: "+callsign+" going portable to "+assets.first[:name]+"["+assets.first[:code]+"] on "+freq+"/"+mode+" at "+al_date+" "+al_time+" UTC"
      end
      if assets.first[:external]==false then
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
end

