class ContactsController < ApplicationController
  before_action :signed_in_user, only: [:edit, :update, :editgrid]

  def editgrid
    @contact=Contact.new
    @contacts=Contact.find_by_sql [ " select * from contacts where id=-99 " ]
    tz=Timezone.find_by_id(current_user.timezone)
    @contact.date=Time.now.in_time_zone(tz.name).to_date.to_s
    @contact.timezone=current_user.timezone
    if current_user then @contact.callsign1=current_user.callsign end
    if params[:hut1] then
      @contact.hut1_id=params[:hut1].to_i
      hut=Hut.find_by_id(@contact.hut1_id)
      if hut then
              @contact.x1=hut.x
              @contact.y1=hut.y
      end
    end
    if params[:park1] then @contact.park1_id=params[:park1].to_i end
    if params[:island1] then @contact.island1_id=params[:island1].to_i end
    if params[:summit1] then 
      @contact.summit1_id=params[:summit1].to_i
      summit=SotaPeak.find_by_id(@contact.summit1_id)
      if summit then
              @contact.x1=summit.x
              @contact.y1=summit.y
      end
   end

  end

  def index_prep
    whereclause="true"
    if params[:filter] then
      @filter=params[:filter]
      whereclause="is_"+@filter+" is true"
    end
    if params[:contact_qrp] then
      whereclause=whereclause+" and is_qrp1=true and is_qrp2=true"
    end

    if params[:user] then
         @fullcontacts=Contact.find_by_sql [ "select * from contacts where (callsign1='"+params[:user]+"' or callsign2='"+params[:user]+"') and "+whereclause+" order by date desc, time desc" ]
         @user=User.find_by(callsign: params[:user])
    elsif params[:hut] then
         @fullcontacts=Contact.find_by_sql [ "select * from contacts where (hut1_id="+params[:hut]+" or hut2_id="+params[:hut]+") and "+whereclause+" order by date desc, time desc" ]
         @hut=Hut.find_by_id(params[:hut])

    elsif params[:park] then
         @fullcontacts=Contact.find_by_sql [ "select * from contacts where (park1_id="+params[:park]+" or park2_id="+params[:park]+") and "+whereclause+" order by date desc, time desc" ]
         @park=Park.find_by_id(params[:park])

    elsif params[:island] then
         @fullcontacts=Contact.find_by_sql [ "select * from contacts where (island1_id="+params[:island]+" or island2_id="+params[:island]+") and "+whereclause+" order by date desc, time desc" ]
         @island=Island.find_by_id(params[:island])

    else 
      if current_user  then
       if  current_user.is_admin and params[:all] then
         @fullcontacts=Contact.find_by_sql [ "select * from contacts where "+whereclause+" order by date desc, time desc" ]
         @all=true
       else
         @fullcontacts=Contact.find_by_sql [ "select * from contacts where (callsign1='"+current_user.callsign+"' or callsign2='"+current_user.callsign+"') and "+whereclause+" order by date desc, time desc" ]
         @user=current_user
       end
     end
    end 
    if params[:user_qrp] and (params[:user] or signed_in?) then
      if params[:user] then callsign=params[:user].upcase else callsign=current_user.callsign.upcase end
      cs=[]

      @fullcontacts.each do |contact|
        if (contact.callsign1.upcase==callsign and contact.is_qrp1) or 
          (contact.callsign2.upcase==callsign and contact.is_qrp2) then 
            cs.push(contact)
        end 
     end
     @fullcontacts=cs
    end
 @contacts=@fullcontacts.paginate(:per_page => 20, :page => params[:page]) 
  end
  
  def index
    index_prep()
    respond_to do |format|
      format.html
      format.js
      format.csv { send_data contacts_to_csv(@fullcontacts), filename: "contacts-#{Date.today}.csv" }
    end
  end

  def new2
    redirect_to '/contacts/new'
  end

  def select2
    if params[:id]=="new" then
        @contact = Contact.new
        @contact.callsign1=params[:callsign1]
        @contact.callsign2=params[:callsign2]
        @contact.date=params[:date]
        @contact.timezone=current_user.timezone 
      render 'new2'
    else
      @contact=Contact.find_by_id(params[:id])
      
      if @contact then 
        @contact.date=@contact.localdate(current_user)
        @contact.time=@contact.localtime(current_user)
        @contact.timezone=current_user.timezone

        render 'edit'
      else
        redirect_to root_path
      end
    end
  end

  def show
    if(!(@contact = Contact.find_by_id(params[:id].to_i)))
      redirect_to '/'
    end
  end

  def edit
    if params[:referring] then @referring=params[:referring] end

    if(!(@contact = Contact.where(id: params[:id]).first))
      redirect_to '/'
    end
    if(@contact.location1==nil and @contact.x1 and @contact.y1) then
      convert_location_params1()
    end
    if(@contact.location2==nil and @contact.x2 and @contact.y2) then
      convert_location_params2()
    end
    @contact.date=@contact.localdate(current_user)
    @contact.time=@contact.localtime(current_user)
    @contact.timezone=current_user.timezone
  end

  def new
    @contact = Contact.new
    if current_user then @contact.callsign1=current_user.callsign end
    tz=Timezone.find_by_id(current_user.timezone)
    @contact.date=Time.now.in_time_zone(tz.name).to_date.to_s
    if params[:hut1] then 
      @contact.hut1_id=params[:hut1].to_i 
    end
    if params[:park1] then @contact.park1_id=params[:park1].to_i end
    if params[:island1] then @contact.island1_id=params[:island1].to_i end
  end

  def check
   if @contact.callsign1 and @contact.callsign1.length>0 and @contact.callsign2 and @contact.callsign2.length>0 and @contact.date then
    @contacts=Contact.find_by_sql [ "select * from contacts where date(time at time zone 'UTC' at time zone '"+current_user.timezonename+"')='"+@contact.date.to_date.to_s+"' and ((callsign1='"+@contact.callsign1.upcase+"' and callsign2='"+@contact.callsign2.upcase+"') or (callsign1='"+@contact.callsign2.upcase+"' and callsign2='"+@contact.callsign1.upcase+"'))"]

    if @contacts and @contacts.length>0 then
      render 'select'
    else
      @contact.timezone=current_user.timezone

      render 'new2'
    end
   else
     new()
     render 'new'
   end
  end

 def create
    if signed_in?  then

      if params[:commit] and params[:commit]=='Next' then 
        @contact = Contact.new
        @contact.callsign1=params[:contact][:callsign1]
        @contact.callsign2=params[:contact][:callsign2]
        if @contact.callsign1 then @contact.callsign1=@contact.callsign1.split('/')[0] end
        if @contact.callsign2 then @contact.callsign2=@contact.callsign2.split('/')[0] end
        @contact.date=params[:contact][:date]
        @contact.timezone=params[:contact][:timezone]
        @contact.hut1_id=params[:hut1_id]
        hut=Hut.find_by_id(@contact.hut1_id)
        if hut then 
            @contact.x1=hut.x
            @contact.y1=hut.y
        end
        @contact.park1_id=params[:park1_id]
        @contact.island1_id=params[:island1_id]
        check()
      else

        @contact = Contact.new(contact_params)
        if @contact.callsign1 then @contact.callsign1=@contact.callsign1.split('/')[0] end
        if @contact.callsign2 then @contact.callsign2=@contact.callsign2.split('/')[0] end

        convert_location_params1()
        convert_location_params2()
        convert_to_utc()
        @contact.createdBy_id=current_user.id
    
        if @contact.save
          @contact.reload
          update_score(@contact.callsign1)
          update_score(@contact.callsign2)
          post_notification(@contact)
          if params[:referring]=='index' then
            index_prep()
            render 'index'
          elsif params[:referring]=='editgrid' then
            @contact = @contact.dup
            @contact.callsign2=nil
            @contact.signal1=nil
            @contact.signal2=nil
            @contact.loc_desc2=nil
            @contact.comments1=nil
            if current_user then tz=current_user.timezonename else tz=Timezone.first.name end
            if @contact.hut1_id and @contact.park1_id then 
              @contacts=(Contact.find_by_sql [ " select * from contacts where callsign1='"+@contact.callsign1+"' and date(time at time zone 'UTC' at time zone '"+tz+"') ='"+@contact.localdate(current_user)+"' and hut1_id="+@contact.hut1_id.to_s+" and park1_id="+@contact.park1_id.to_s+" and loc_desc1='"+@contact.loc_desc1+"' " ]).sort_by{|c| c.time}
            else
              @contacts=(Contact.find_by_sql [ " select * from contacts where callsign1='"+@contact.callsign1+"' and date(time at time zone 'UTC' at time zone '"+tz+"')='"+@contact.localdate(current_user)+"' and loc_desc1='"+@contact.loc_desc1+"' " ]).sort_by{|c| c.time}
            end
            @contact.date=@contact.localdate(current_user)
            @contact.time=@contact.localtime(current_user)
            @contact.timezone=current_user.timezone
            render 'editgrid'
          else
            render 'show'
          end

        else
          if params[:referring]=='editgrid' then
            if @contact.time then 
              if current_user then tz=current_user.timezonename else tz=Timezone.first.name end
              if @contact.hut1_id and @contact.park1_id then 
                @contacts=(Contact.find_by_sql [ " select * from contacts where callsign1='"+@contact.callsign1+"' and date(time at time zone 'UTC' at time zone '"+tz+"') ='"+@contact.localdate(current_user)+"' and hut1_id="+@contact.hut1_id.to_s+" and park1_id="+@contact.park1_id.to_s+" and loc_desc1='"+@contact.loc_desc1+"' " ]).sort_by { |c| c.time}
              else
                @contacts=(Contact.find_by_sql [ " select * from contacts where callsign1='"+@contact.callsign1+"' and date(time at time zone 'UTC' at time zone '"+tz+"')='"+@contact.localdate(current_user)+"' and loc_desc1='"+@contact.loc_desc1+"' " ]).sort_by { |c| c.time}
              end
            else 
              @contacts=[]
            end
            @contact.date=@contact.localdate(current_user)
            @contact.time=@contact.localtime(current_user)
            @contact.timezone=current_user.timezone
            render 'editgrid'
          else
            @contact.date=@contact.localdate(current_user)
            @contact.time=@contact.localtime(current_user)
            @contact.timezone=current_user.timezone
            render 'new2'
          end
        end
      end
    else
      redirect_to '/'
    end
 end

 def update
   puts "cu", current_user.callsign
   puts "cs1", params[:callsign1]
   puts "cs2", params[:callsign2]
    if current_user  and (current_user.callsign==params[:contact][:callsign1].upcase or current_user.callsign==params[:contact][:callsign2].upcase or current_user.is_admin) then
    if params[:delete] then
      contact = Contact.find_by_id(params[:id])
      if contact then
        cs1=contact.callsign1
        cs2=contact.callsign2

        @contact=contact.dup

        if contact.destroy
          flash[:success] = "Contact deleted, id:"+params[:id]
          update_score(cs1)
          update_score(cs2)
        if params[:referring]=='editgrid' then
            @contact.callsign2=nil
            @contact.time=nil
            @contact.signal1=nil
            @contact.signal2=nil
            @contact.loc_desc2=nil
            @contact.comments1=nil
            if @contact.hut1_id and @contact.park1_id then @contacts=(Contact.find_by_sql [ " select * from contacts where callsign1='"+@contact.callsign1+"' and date='"+@contact.date.to_s+"' and hut1_id="+@contact.hut1_id.to_s+" and park1_id="+@contact.park1_id.to_s+" and loc_desc1='"+@contact.loc_desc1+"' " ]).sort_by { |c| c.time} else
              @contacts=(Contact.find_by_sql [ " select * from contacts where callsign1='"+@contact.callsign1+"' and date='"+@contact.date.to_s+"' and loc_desc1='"+@contact.loc_desc1+"' " ]).sort_by { |c| c.time}
            end
            render 'editgrid'
          else
            index_prep()
            render 'index'
          end
        end
      else
        edit()
        render 'edit'
      end
    else
      if(!@contact = Contact.find_by_id(params[:id]))
          flash[:error] = "Contact does not exist: "+@contact.id.to_s

          #tried to update a nonexistant contact
          render 'edit'
      end

      #params[:contact][:hut1_id]=params[:contact][:hut1_id].split(',')[0].to_i
      old_user1=@contact.callsign1
      old_user2=@contact.callsign2
      @contact.assign_attributes(contact_params)
      if @contact.callsign1 then @contact.callsign1=@contact.callsign1.split('/')[0] end
      if @contact.callsign2 then @contact.callsign2=@contact.callsign2.split('/')[0] end

      @contact.hut1_id=params[:contact][:hut1_id].split(',')[0].to_i
      puts @contact.hut1_id
      convert_location_params1()
      convert_location_params2()
      convert_to_utc()
      @contact.createdBy_id=current_user.id

      if @contact.save
        flash[:success] = "Contact details updated"
        update_score(@contact.callsign1)
        update_score(@contact.callsign2)
        update_score(old_user1)
        update_score(old_user2)

        # Handle a successful update.
        if params[:referring]=='index' then
          index_prep()
          render 'index'
        elsif params[:referring]=='editgrid' then
            @contact.callsign2=nil
            @contact.time=nil
            @contact.signal1=nil
            @contact.signal2=nil
            @contact.loc_desc2=nil
            @contact.comments1=nil
            if @contact.hut1_id and @contact.park1_id then @contacts=(Contact.find_by_sql [ " select * from contacts where callsign1='"+@contact.callsign1+"' and date='"+@contact.date.to_s+"' and hut1_id="+@contact.hut1_id.to_s+" and park1_id="+@contact.park1_id.to_s+" and loc_desc1='"+@contact.loc_desc1+"' " ]).sort_by { |c| c.time} else
              @contacts=(Contact.find_by_sql [ " select * from contacts where callsign1='"+@contact.callsign1+"' and date='"+@contact.date.to_s+"' and loc_desc1='"+@contact.loc_desc1+"' " ]).sort_by { |c| c.time}
            end
            render 'editgrid'

        else
          render 'show'
        end
      else
        render 'edit'
      end
    end
  else
    redirect_to '/'
  end
 end

 def contacts_to_csv(items)
    if signed_in? then
      require 'csv'
      csvtext=""
      if items and items.first then
        columns=[]; items.first.attributes.each_pair do |name, value| if !name.include?("password") and !name.include?("digest") and !name.include?("token") then columns << name end end
        columns=columns+["hut1_name","park1_name","island1_name","hut2_name","park2_name","island2_name"]
        csvtext << columns.to_csv
        items.each do |item|
           fields=[]; item.attributes.each_pair do |name, value| if !name.include?("password") and !name.include?("digest") and !name.include?("token") then fields << value end end
           fields=fields+[item.hut1_name, item.park1_name, item.hut2_name, item.park2_name]
           csvtext << fields.to_csv
        end
     end
     csvtext
   end
 end

 def data
            contacts = Contact.find_by_sql [ ' select * from contacts where id = -99' ] 

            render :json => {
                 :total_count => contacts.length,
                 :pos => 0,
                 :rows => contacts.map do |contact|
                 {
                   :id => contact.id,
                   :data => [contact.id, contact.date, contact.hut1_id, contact.parl1_id, contact.x1, contact.y1, contact.altitude1, contact.loc_desc1, contact.power1, contact.transceiver1, contact.antenna1, contact.comments1, contact.callsign2, contact.time, contact.frequency, contact.mode, contact.signal1, contact.signal2, contact.loc_desc2]
                 }
                 end
            }
 end

 def db_action
  if signed_in? and current_user.is_modifier then
    @mode = params["!nativeeditor_status"]
    callsign1 = params['c0']
    date = params['c1']
    callsign2 = params['c13']
    time = params['c14']
    frequency = params['c15']
    mode = params['c16']
    signal1 = params['c17']
    signal2 = params['c18']
    loc_desc2 = params['c19']
    hut1_id = params['c3']
    park1_id = params['c4']
    x1 = params['c5']
    y1 = params['c6']
    altitude1 = params['c7']
    loc_desc1 = params['c8']
    power1 = params['c9']
    transceiver1 = params['c10']
    antenna1 = params['c11']
    comments1 = params['c12']

    @id = params["gr_id"]

    case @mode
    when "inserted"
        contact = Contact.create :callsign1 => callsign1,:hut1_id => hut1_id, :park1_id => park1_id, :x1 => x1, :y1 => y1, :altitude1 => altitude1, :loc_desc1 => loc_desc1, :power1 => power1, :transceiver1 => transceiver1, :antenna1 => antenna1, :comments1 => comments1, :callsign2 => callsign2, :time => time, :frequency => frequency, :mode => mode,:signal1 => signal1, :signal2 => signal2, :loc_desc2 => loc_desc2
       if contact then
          @tid = contact.id
       else
          @mode="error"
          @tid=nil
       end

    when "deleted"
        if Contact.find(@id).destroy then
          @tid = @id
        else
          @mode-"error"
          @tid=nil
       end

    when "updated"
        @contact = Contact.find(@id)
        if @contact.x1!=x1 or @contact.y1!=y1 then need_convert=true else need_convert=false end
        @contact.callsign1 = callsign1
        @contact.hut1_id = hut1_id
        @contact.park1_id = park1_id
        @contact.altitude1 = altitude1
        @contact.loc_desc1 = loc_desc1
        @contact.power1 = power1
        @contact.transceiver1 = transceiver1
        @contact.antenna1 = antenna1
        @contact.comments1 = comments1
        @contact.callsign2 = callsign2
        @contact.time = time
        @contact.frequency = frequency
        @contact.mode = mode
        @contact.signal1 = signal1
        @contact.signal2 = signal2
        @contact.loc_desc2 = loc_desc2
        if x1!="" then @contact.x1 = x1 else @contact.x1 = nil end
        if y1!="" then @contact.y1 = y1 else @contact.y1 = nil end

        if need_convert then convert_location_params() end
        if @contact.x1 and @contact.y1 then
          @contact.x1 = @contact.x1.to_i
          @contact.y1 = @contact.y1.to_i
        end
        if !@contact.save then @mode="error" end

        @tid = @id
    end
  end
end
  private
  def contact_params
    params.require(:contact).permit(:id, :callsign1, :user1_id, :power1, :signal1, :transceiver1, :antenna1, :comments1, :location1, :park1, :callsign2, :user2_id, :power2, :signal2, :transceiver2, :antenna2, :comments2, :hut2, :park2, :date, :time, :timezone,  :frequency, :mode, :loc_desc1, :loc_desc2, :x1, :y1, :altitude1, :locationi1, :x2, :y2, :altitude2, :location2, :is_active, :hut1_id, :hut2_id, :park1_id, :park2_id, :island1_id, :island2_id, :is_qrp1, :is_qrp2, :is_portable1, :is_portable2, :summit1_id, :summit2_id)
  end

  def convert_to_utc
    if @contact.time and @contact.date 
        if @contact.timezone==nil then @contact.timezone=current_user.timezone end
        tz=Timezone.find_by_id(@contact.timezone)
        t=(@contact.date.strftime('%Y-%m-%d')+" "+@contact.time.strftime('%H:%M')).in_time_zone(tz.name)
        @contact.time=t.in_time_zone('UTC')
        @contact.date=t.in_time_zone('UTC') 
        @contact.timezone=Timezone.where(:name => 'UTC').first.id
    end
  end

  def post_notification(contact)
    if contact then
      details1=contact.location1_text
      details2=contact.location2_text
      if !details1 or details1.length<2 then details1="..." end
      if !details2 or details2.length<2 then details2="..." end
      details=contact.callsign1+" and "+contact.callsign2+" logged a contact between "+details1+" and "+details2+" on "+contact.localdate(current_user)

      hp=HotaPost.new
      hp.title=details
      hp.url="ontheair.nz/contacts/"+contact.id.to_s
      hp.save
      hp.reload
      i=Item.new
      i.item_type="hota"
      i.item_id=hp.id
      i.save
    end
  end

  def convert_location_params1
   if(@contact.x1 and @contact.y1)


       # convert to WGS84 (EPSG4326) for database 
       fromproj4s= Projection.find_by_id(2193).proj4
       toproj4s=  Projection.find_by_id(4326).proj4

       fromproj=RGeo::CoordSys::Proj4.new(fromproj4s)
       toproj=RGeo::CoordSys::Proj4.new(toproj4s)

       xyarr=RGeo::CoordSys::Proj4::transform_coords(fromproj,toproj,@contact.x1,@contact.y1)

       params[:location1]=xyarr[0].to_s+" "+xyarr[1].to_s
       @contact.location1='POINT('+params[:location1]+')'

      #if altitude is not entered, calculate it from map 
      if !@contact.altitude1 or @contact.altitude1.to_i == 0 then
         #get alt from map if it is blank or 0
         altArr=Dem30.find_by_sql ["
            select ST_Value(rast, ST_GeomFromText(?,4326))  rid
               from dem30s
               where ST_Intersects(rast,ST_GeomFromText(?,4326));",
               'POINT('+params[:location1]+')',
               'POINT('+params[:location1]+')']

         @contact.altitude1=altArr.first.try(:rid).to_i
       end
    else
       @contact.location1=nil
    end
  end
  def convert_location_params2
   if(@contact.x2 and @contact.y2)


       # convert to WGS84 (EPSG4326) for database 
       fromproj4s= Projection.find_by_id(2193).proj4
       toproj4s=  Projection.find_by_id(4326).proj4

       fromproj=RGeo::CoordSys::Proj4.new(fromproj4s)
       toproj=RGeo::CoordSys::Proj4.new(toproj4s)

       xyarr=RGeo::CoordSys::Proj4::transform_coords(fromproj,toproj,@contact.x2,@contact.y2)

       params[:location2]=xyarr[0].to_s+" "+xyarr[1].to_s
       @contact.location2='POINT('+params[:location2]+')'

      #if altitude is not entered, calculate it from map 
      if !@contact.altitude2 or @contact.altitude2.to_i == 0 then
         #get alt from map if it is blank or 0
         altArr=Dem30.find_by_sql ["
            select ST_Value(rast, ST_GeomFromText(?,4326))  rid
               from dem30s
               where ST_Intersects(rast,ST_GeomFromText(?,4326));",
               'POINT('+params[:location2]+')',
               'POINT('+params[:location2]+')']

         @contact.altitude2=altArr.first.try(:rid).to_i
       end
    else
       @contact.location2=nil
    end
  end
end
