class StaticPagesController < ApplicationController
 
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
        Resque.enqueue(UpdateSotaActivations)    
            
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

  def about
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

      #check for new spots from external servers (maybe move this to a scheduled job?)
      #ExternalSpot.fetch

      #read spots from db
      @all_spots=ExternalSpot.where("time>'"+onehourago+"'")
     
      items=Item.where(:topic_id => 35, :item_type => "post").order(:created_at).reverse
      @hota_spots=[]
      items.each do |i|
        p=Post.find(i.item_id)
        if p and p.referenced_date and p.referenced_date>Time.now.to_date-1.days then 
        if (p.referenced_time and p.referenced_time>Time.now-1.hours) or not p.referenced_time then
          @hota_spots.push(p)
        end
      end
      end
     
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
 
      if @all_spots then @all_spots.sort_by!{|hsh| hsh[:date].to_s+hsh[:time].to_s}.reverse! end

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

      #url="https://api2.sota.org.uk/api/alerts/12?client=sotawatch&user=anon"
      #alerts=JSON.parse(open(url).read)
      #if alerts then
      #  zl_alerts=alerts.find_all { |l| l["associationCode"][0..1]=="ZL" }
      #  vk_alerts=alerts.find_all { |l| l["associationCode"][0..1]=="VK" }
      #  zlvk_sota_alerts=zl_alerts+vk_alerts
      #else
        zlvk_sota_alerts=[]
      #end

     # pota_alerts=get_pota_alerts
     # if pota_alerts then
     #   zl_alerts=pota_alerts.find_all { |l| l["Reference"][0..1]=="ZL" }
     #   vk_alerts=pota_alerts.find_all { |l| l["Reference"][0..1]=="VK" }
     #   zlvk_pota_alerts=zl_alerts+vk_alerts
     # else
        zlvk_pota_alerts=[]
     # end

      items=Item.where(:topic_id => 1, :item_type => "post").order(:created_at).reverse
      @hota_alerts=[]
      items.each do |i|
        p=Post.find(i.item_id)
        if p and p.referenced_date and p.referenced_date>Time.now-(p.duration||1).days then @hota_alerts.push(p) end
      end
      if @hota_alerts and @hota_alerts.count>0 then @hota_alerts=@hota_alerts.sort_by { |h| if h.referenced_date then h.referenced_date.strftime("%Y-%m-%d")+" "+if h.referenced_time then h.referenced_time.strftime("%H:%M") else "" end else "" end }.reverse end

      url="http://parksnpeaks.org/api/ALERTS/"
      pnp_alerts=JSON.parse(open(url).read)

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



def get_pota_alerts
  keys=[]
  th=nil
  url="https://stats.parksontheair.com/spotting/scheduling.php"
  page=open(url).read
  start=page.index("table id='example'")
  if start then 
    table=page[start..-1]
    start=table.index("<th>")
    fin=table.index("tbody")
    if start and fin then 
     th=table[start..fin-2]
    end
  end
  
  while th and th.length>0 
  
    key=th[4..th.index("</th>")-1]
    start=th.index("</th>")
    if start then th=th[start..-1] 
      start=th.index("<th>")
      if start then th=th[start..-1] else th=nil end
    else th=nil end
    
    if key and key.length>0 then 
      keys.push(key)
    end
  end

  pota_alerts=[]
  if table then 
  start=table.index("tbody")
  tbody=table[start..-1]
  while tbody and tbody.length>0 
    values=[]
    start=tbody.index("<tr>")
    fin=tbody.index("</tr>")
    if start and fin then  
      tr=tbody[start..fin]
      tbody=tbody[fin+5..-1]
  
      while tr and tr.length>0
        start=tr.index("<td>")
        fin=tr.index("</td>")
        if start and fin then 
          td=tr[start+4..fin-1]
          tr=tr[fin+5..-1]
        else
          td=nil
          tr=nil
        end
        if td and td.length>0 then
          values.push(td)
        end  
      end
    else
      tbody=nil
      values=nil
    end
    if values then 
      pota_alert=Hash[keys.zip(values.map {|i| i})]
      pota_alerts.push(pota_alert)
    end
  end
  end
  pota_alerts
end
 
end
