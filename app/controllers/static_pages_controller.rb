class StaticPagesController < ApplicationController
  def home
      @parameters=params_to_query

      @users=User.users_with_assets

       @static_page=true
       @sortby=params[:sortby]
       if !@sortby or @sortby=='' then @sortby="hut" end
       @brief=true
       @fulllogs=Log.find_by_sql [ " select * from logs order by date desc " ]
       @logs=@fulllogs.paginate(:per_page => 20, :page => params[:page])
  end

  def results
      @parameters=params_to_query

      @users=User.users_with_assets

       @static_page=true
       @sortby=params[:sortby]
       if !@sortby or @sortby=='' then @sortby="hut" end
  end
  def help
  end

  def about
  end

  def spots
      url="https://api2.sota.org.uk/api/spots/50/all%7Cssb?client=sotawatch&user=anon"
      spots=JSON.parse(open(url).read)
      if spots then
        zl_spots=spots.find_all { |l| l["associationCode"][0..1]=="ZL" }
        vk_spots=spots.find_all { |l| l["associationCode"][0..1]=="VK" }
        zlvk_sota_spots=(zl_spots)+(vk_spots)
      else
        zlvk_sota_spots=[] 
      end


      url="https://api.pota.us/spot/activator"
      spots=JSON.parse(open(url).read)
      if spots then
        zl_spots=spots.find_all { |l| l["reference"][0..1]=="ZL" }
        vk_spots=spots.find_all { |l| l["reference"][0..1]=="VK" }
        zlvk_pota_spots=(zl_spots)+(vk_spots)
      else
        zlvk_pota_spots=[] 
      end

      items=Item.where(:topic_id => 35, :item_type => "post").order(:created_at).reverse
      @hota_spots=[]
      items.each do |i|
        p=Post.find(i.item_id)
        if p and p.referenced_date and p.referenced_date>Time.now.to_date-1.days then @hota_spots.push(p) end
      end

      url="http://www.parksnpeaks.org/api/ALL"
      pnp_spots=JSON.parse(open(url).read)

      
      @all_spots=[]
      zlvk_sota_spots.each do |spot|
         @all_spots.push({
           date: if spot["timeStamp"].to_datetime then spot["timeStamp"].to_datetime.in_time_zone('Pacific/Auckland').strftime("%Y-%m-%d") else "" end,
           time: if spot["timeStamp"].to_datetime then spot["timeStamp"].to_datetime.in_time_zone('Pacific/Auckland').strftime("%H:%M") else "" end,
           callsign: spot["callsign"],
           activatorCallsign: spot["activatorCallsign"],
           code: spot["associationCode"]+"/"+spot["summitCode"],
           name: spot["summitDetails"],
           frequency: spot["frequency"],
           mode: spot["mode"],
           comments: spot["comments"],
           type: "SOTA"})
 
      end

      zlvk_pota_spots.each do |spot|
         @all_spots.push({     
           date: if spot["spotTime"].to_datetime then spot["spotTime"].to_datetime.in_time_zone('Pacific/Auckland').strftime("%Y-%m-%d") else "" end,
           time: if spot["spotTime"].to_datetime then spot["spotTime"].to_datetime.in_time_zone('Pacific/Auckland').strftime("%H:%M") else "" end,
           callsign: spot["spotter"],
           activatorCallsign: spot["activator"],
           code: spot["reference"],
           name: spot["name"],
           frequency: spot["frequency"],
           mode: spot["mode"],
           comments: spot["comments"],
           type: "POTA"})
      end
      pnp_spots.each do |spot|
       if spot["WWFFid"][0..1]=="VK" or spot["WWFFid"][0..1]=="ZL" or spot["actLocation"][0..1]=="VK" or spot["actLocation"][0..1]=="ZL" or spot["actCallsign"][0..1]=="ZL" or spot["actCallsign"][0..1]=="VK" then 
         @all_spots.push({     
           date: if spot["actTime"].to_datetime then spot["actTime"].to_datetime.in_time_zone('Pacific/Auckland').strftime("%Y-%m-%d") else "" end,
           time: if spot["actTime"].to_datetime then spot["actTime"].to_datetime.in_time_zone('Pacific/Auckland').strftime("%H:%M") else "" end,
           callsign: spot["actSpoter"],
           activatorCallsign: spot["actCallsign"],
           code: if spot["WWFFid"] and spot["WWFFid"].length>0 then spot["WWFFid"] else spot["actLocation"] end,
           name: if spot["WWFFid"] and spot["WWFFid"].length>0 then spot["actLocation"] else spot["altLocation"] end,
           frequency: spot["actFreq"],
           mode: spot["actMode"],
           comments: spot["actComments"],
           type: "PnP: "+spot["actClass"]})
      end end

      if @all_spots then @all_spots.sort_by!{|hsh| hsh[:time]}.sort_by!{|hsh| hsh[:date]}.reverse! end



  end

  def alerts
      url="https://api2.sota.org.uk/api/alerts/12?client=sotawatch&user=anon"
      alerts=JSON.parse(open(url).read)
      if alerts then
        zl_alerts=alerts.find_all { |l| l["associationCode"][0..1]=="ZL" }
        vk_alerts=alerts.find_all { |l| l["associationCode"][0..1]=="VK" }
        zlvk_sota_alerts=zl_alerts+vk_alerts
      else
        zlvk_sota_alerts=[]
      end

      pota_alerts=get_pota_alerts
      if pota_alerts then
        zl_alerts=pota_alerts.find_all { |l| l["Reference"][0..1]=="ZL" }
        vk_alerts=pota_alerts.find_all { |l| l["Reference"][0..1]=="VK" }
        zlvk_pota_alerts=zl_alerts+vk_alerts
      else
        zlvk_pota_alerts=[]
      end

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
          starttime: if alert["dateActivated"].to_datetime then alert["dateActivated"].to_datetime.in_time_zone('Pacific/Auckland').strftime("%Y-%m-%d %H:%M") else "" end,
          activatingCallsign: alert["activatingCallsign"],
          code: alert["associationCode"]+"/"+alert["summitCode"],
          name: alert["summitDetails"],
          frequency: alert["frequency"],
          mode: alert["mode"],
          comments: alert["comments"],
          type: "SOTA"})    
     end
     zlvk_pota_alerts.each do |alert|
       @all_alerts.push({
          starttime: if alert["Start Date"].to_datetime then alert["Start Date"].to_datetime.in_time_zone('Pacific/Auckland').strftime("%Y-%m-%d %H:%M")+(if alert["End Date"].to_datetime then " to "+alert["End Date"].to_datetime.in_time_zone('Pacific/Auckland').strftime("%Y-%m-%d %H:%M") else "" end) else "" end,
          activatingCallsign: alert["Activator"],
          code: alert["Reference"],
          name: alert["Park Name"],
          frequency: alert["Frequecies"],
          mode: "",
          comments: alert["Comments"],
          type: "POTA"})   
     end

     pnp_alerts.each do |alert|
       @all_alerts.push({
          starttime: if alert["alTime"].to_datetime then alert["alTime"].to_datetime.in_time_zone('Pacific/Auckland').strftime("%Y-%m-%d %H:%M") + ( if alert["alDay"]=="1" then " (Day)" elsif alert["alDay"]=="2" then " (Morning)" elsif alert["alDay"]=="3" then " (Afternoon)" elsif alert["alDay"]=="4" then " (Evening)" elsif alert["alDay"]=="5" then " (Overnight)"  else "" end) else "" end,
          activatingCallsign: alert["CallSign"],
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
