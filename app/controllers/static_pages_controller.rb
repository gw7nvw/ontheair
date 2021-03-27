class StaticPagesController < ApplicationController
  def home
       @static_page=true
       @sortby=params[:sortby]
       @brief=true
       @contacts=Contact.find_by_sql [ " select * from contacts order by time desc limit 10 " ]
  end

  def about
  end

  def spots
      url="https://api2.sota.org.uk/api/spots/50/all%7Cssb?client=sotawatch&user=anon"
      spots=JSON.parse(open(url).read)
      if spots then
        zl_spots=spots.find_all { |l| l["associationCode"][0..1]=="ZL" }
        vk_spots=spots.find_all { |l| l["associationCode"][0..1]=="VK" }
        @zlvk_sota_spots=(zl_spots)+(vk_spots)
      else
        @zlvk_sota_spots=[] 
      end

      if @zlvk_sota_spots then @zlvk_sota_spots.sort_by!{|hsh| hsh["timeStamp"]}.reverse! end

      url="https://api.pota.us/spot/activator"
      spots=JSON.parse(open(url).read)
      if spots then
        zl_spots=spots.find_all { |l| l["reference"][0..1]=="ZL" }
        vk_spots=spots.find_all { |l| l["reference"][0..1]=="VK" }
        @zlvk_pota_spots=(zl_spots)+(vk_spots)
      else
        @zlvk_pota_spots=[] 
      end
      if @zlvk_pota_spots then @zlvk_pota_spots.sort_by!{|hsh| hsh["spotTime"]}.reverse! end

      items=Item.where(:topic_id => 35, :item_type => "post").order(:created_at).reverse
      @hota_spots=[]
      items.each do |i|
        p=Post.find(i.item_id)
        if p and p.referenced_date and p.referenced_date>Time.now.to_date-1.days then @hota_spots.push(p) end
      end

  end

  def alerts
      url="https://api2.sota.org.uk/api/alerts/12?client=sotawatch&user=anon"
      alerts=JSON.parse(open(url).read)
      if alerts then
        zl_alerts=alerts.find_all { |l| l["associationCode"][0..1]=="ZL" }
        vk_alerts=alerts.find_all { |l| l["associationCode"][0..1]=="VK" }
        @zlvk_sota_alerts=zl_alerts+vk_alerts
      else
        @zlvk_sota_alerts=[]
      end
      if @zlvk_sota_alerts then @zlvk_sota_alerts.sort_by!{|hsh| hsh["dateActivated"]}.reverse! end

      pota_alerts=get_pota_alerts
      if pota_alerts then
        zl_alerts=pota_alerts.find_all { |l| l["Reference"][0..1]=="ZL" }
        vk_alerts=pota_alerts.find_all { |l| l["Reference"][0..1]=="VK" }
        @zlvk_pota_alerts=zl_alerts+vk_alerts
      else
        @zlvk_pota_alerts=[]
      end
      if @zlvk_pota_alerts then @zlvk_pota_alerts.sort_by!{|hsh| hsh["Start Date"]}.reverse! end

      items=Item.where(:topic_id => 1, :item_type => "post").order(:created_at).reverse
      @hota_alerts=[]
      items.each do |i|
        p=Post.find(i.item_id)
        if p and p.referenced_date and p.referenced_date>Time.now-(p.duration||1).days then @hota_alerts.push(p) end
      end
      if @hota_alerts and @hota_alerts.count>0 then @hota_alerts=@hota_alerts.sort_by { |h| if h.referenced_date then h.referenced_date.strftime("%Y-%m-%d")+" "+if h.referenced_time then h.referenced_time.strftime("%H:%M") else "" end else "" end }.reverse end
     puts "@hota_alerts.count"
     puts @hota_alerts.count
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
          puts td
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
