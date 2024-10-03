# typed: false
class StaticPagesController < ApplicationController
include ApplicationHelper
 
  def ack_news
    if current_user then
      current_user.hide_news_at=Time.now()
      current_user.save
    end
    redirect_to '/'
  end

  def home
      #Hanging this here just because
      timeNow=Time.now()
      as=AdminSettings.last
      if !as.last_sota_activation_update_at or (as.last_sota_activation_update_at+30.days)<timeNow then
        if ENV["RAILS_ENV"] == "production" then
            Resque.enqueue(UpdateExternalActivations)    
        elsif ENV["RAILS_ENV"] == "development"  then
            as.last_sota_activation_update_at=Time.now()
            as.save
            ExternalActivation.import_sota
            ExternalActivation.import_pota
        else
            #do nothing in test
        end
      end

      spots()
      tzid=3
      if current_user then 
        tzid=current_user.timezone
        ack_time=current_user.hide_news_at
      end 
      if !ack_time then  ack_time="1900-01-01" end

      @tz=Timezone.find(tzid)

      @parameters=params_to_query
      @max_rows=30
      results
      @users=@full_users

      @static_page=true
      @brief=true
      @fulllogs=Log.find_by_sql [ " select * from logs where asset_codes != '{}' order by date desc limit 20 " ]
      @logs=@fulllogs.paginate(:per_page => 20, :page => params[:page])
   
      @items=Item.find_by_sql [ "select * from items where (topic_id = 4 or topic_id=42 )and item_type = 'post' and created_at>'#{ack_time}' order by created_at desc limit 4;" ]
  end

  def recent
      @parameters=params_to_query
      @fulllogs=Log.find_by_sql [ " select * from logs order by date desc " ]
      @logs=@fulllogs.paginate(:per_page => 20, :page => params[:page])
  end

  def results
      if !@max_rows then @max_rows=2000 end

      @parameters=params_to_query
      @scoreby=params[:scoreby] 
      if !@scoreby or @scoreby=='' then @scoreby="bagged" end


      @static_page=true
      @sortby=params[:sortby]
      if !@sortby or @sortby=='' then 
         cats=AssetType.where("keep_score = true")
         @sortby=cats[rand(0..cats.count-1)].name
      end
      if @scoreby=="qualified" then
        scorefield="qualified_count_total"
      elsif @scoreby=="activated" then
        scorefield="activated_count_total"
      elsif @scoreby=="chased" then
        scorefield="chased_count_total"
      else
        scorefield="score"
        @scoreby="bagged"
      end

      @full_users=User.users_with_assets(@sortby, scorefield, @max_rows)
      @users=@full_users.paginate(:per_page => 40, :page => params[:page])
  end

  def help
      tzid=3
      if current_user then tzid=current_user.timezone end
      @tz=Timezone.find(tzid)
     @items=Item.where(topic_id: HELP_TOPIC).order(:created_at).reverse
  end

  def faq
      tzid=3
      if current_user then tzid=current_user.timezone end
      @tz=Timezone.find(tzid)
     @items=Item.where(topic_id: FAQ_TOPIC).order(:created_at).reverse
  end

  def spots
      onehourago=Time.at(Time.now().to_i-60*60*1).in_time_zone('UTC').to_s

      @parameters=params_to_query

      tzid=3
      if current_user then tzid=current_user.timezone end
      @tz=Timezone.find(tzid)
    
      @zone="OC"
      if params[:zone] then
        @zone=params[:zone]
      end

      #read spots from db
      @all_spots=ExternalSpot.where("time>'"+onehourago+"'")
    
      @hota_spots=Post.find_by_sql [" 
            select p.* from posts p
            inner join items i on i.item_id=p.id and i.item_type='post' 
            where
              i.topic_id=#{SPOT_TOPIC} and p.referenced_date>'#{Time.now.to_date-1.days}' 
              and (p.referenced_time>'#{Time.now-1.hours}' or p.referenced_time is null)
            order by p.created_at desc;
      "]
      @hota_spots.each do |post|
         createdBy=User.find_by(id: post.created_by_id)
         if createdBy then createdByCallsign=createdBy.callsign else createdByCallsign="" end
         @all_spots.push(ExternalSpot.new(
            spot_type: "ZLOTA",
            time: if post.referenced_time then post.referenced_time.in_time_zone('UTC') else "" end,
            activatorCallsign: post.callsign,
            callsign: createdByCallsign,
            code: post.asset_codes,
            frequency: post.freq,
            mode: post.mode,
            name: post.site,
            comments: (post.title || "") + ' - ' + (post.description || ""),
            id: -post.id
         ))
      end 
 
      if @all_spots then @all_spots=@all_spots.sort_by{|hsh| hsh[:date].to_s+hsh[:time].to_s}.reverse! end

      if @zone and @zone!="all" then
        @all_spots=@all_spots.select{|spot| DxccPrefix.continent_from_call(spot[:activatorCallsign])==@zone}
      end

      if params[:class] then
        @class=params[:class]
        @all_spots=@all_spots.select{|spot| spot[:spot_type].include? @class}
      end

      if params[:mode] then
        @mode=params[:mode]
        @all_spots=@all_spots.select{|spot| @mode.upcase.include? spot[:mode].upcase}
      end
  end

  def alerts
      tzid=3
      if current_user then tzid=current_user.timezone end
      @tz=Timezone.find(tzid)

      zlvk_sota_alerts=[]
      zlvk_pota_alerts=[]

      items=Item.where(:topic_id => 1, :item_type => "post").order(:created_at).reverse
      @hota_alerts=[]
      items.each do |i|
        p=Post.find(i.item_id)
        if p and p.referenced_date and p.referenced_date>Time.now-(p.duration||1).days then @hota_alerts.push(p) end
      end
      if @hota_alerts and @hota_alerts.count>0 then @hota_alerts=@hota_alerts.sort_by { |h| if h.referenced_date then h.referenced_date.strftime("%Y-%m-%d")+" "+if h.referenced_time then h.referenced_time.strftime("%H:%M") else "" end else "" end }.reverse end

      begin
      url="http://parksnpeaks.org/api/ALERTS/"
      pnp_alerts=JSON.parse(open(url).read)
      rescue
        flash[:error]="Received invalid alert data from Parks'n'Peaks. Showing only local alerts"
        pnp_alerts=[]
      end

      @all_alerts=[]
      zlvk_sota_alerts.each do |alert|
        @all_alerts.push({
          starttime: if alert["dateActivated"].to_datetime then alert["dateActivated"].to_datetime.in_time_zone(@tz.name).strftime("%Y-%m-%d %H:%M") else "" end,
          activatingCallsign: alert["activatingCallsign"].strip,
          code: alert["associationCode"]+"/"+alert["summitCode"],
          name: alert["summitDetails"],
          frequency: alert["frequency"],
          mode: alert["mode"],
          comments: alert["comments"],
          type: "SOTA"})    
     end
     zlvk_pota_alerts.each do |alert|
       @all_alerts.push({
          starttime: if alert["Start Date"].to_datetime then alert["Start Date"].to_datetime.in_time_zone(@tz.name).strftime("%Y-%m-%d %H:%M")+(if alert["End Date"].to_datetime then " to "+alert["End Date"].to_datetime.in_time_zone(@tz.name).strftime("%Y-%m-%d %H:%M") else "" end) else "" end,
          activatingCallsign: alert["Activator"].strip,
          code: alert["Reference"],
          name: alert["Park Name"],
          frequency: alert["Frequecies"],
          mode: "",
          comments: alert["Comments"],
          type: "POTA"})   
     end

     pnp_alerts.each do |alert|
       @all_alerts.push({
          starttime: if alert["alTime"].to_datetime then alert["alTime"].to_datetime.in_time_zone(@tz.name).strftime("%Y-%m-%d %H:%M") + ( if alert["alDay"]=="1" then " (Day)" elsif alert["alDay"]=="2" then " (Morning)" elsif alert["alDay"]=="3" then " (Afternoon)" elsif alert["alDay"]=="4" then " (Evening)" elsif alert["alDay"]=="5" then " (Overnight)"  else "" end) else "" end,
          activatingCallsign: alert["CallSign"].strip,
          code: if alert["WWFFID"] and alert["WWFFID"].length>0 then alert["WWFFID"] else alert["Location"] end,
          name: alert["Location"],
          frequency: alert["Freq"],
          mode: alert["MODE"],
          comments: alert["Comments"],
          type: "PnP: "+alert["Class"]})
     end

     if @all_alerts then @all_alerts.sort_by!{|hsh| hsh[:starttime]}.reverse! end

  end



 
end
