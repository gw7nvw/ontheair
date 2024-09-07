class ContactsController < ApplicationController
  before_action :signed_in_user, only: [:edit, :update, :create, :new]

  def index_prep
    whereclause="true"
    if params[:filter] then
      @filter=params[:filter]
      whereclause="is_"+@filter+" is true"
    end
    if params[:contact_qrp] then
      whereclause=whereclause+" and is_qrp1=true and is_qrp2=true"
    end
    if params[:class] and params[:class]!="all" then
      if params[:activator] then
        whereclause=whereclause+" and ('"+params[:class]+"'=ANY(asset1_classes))"
        @activator="on"
      elsif params[:chaser] then
        whereclause=whereclause+" and ('"+params[:class]+"'=ANY(asset2_classes))"
        @chaser="on"
      else
        whereclause=whereclause+" and ('"+params[:class]+"'=ANY(asset1_classes) or '"+params[:class]+"'=ANY(asset2_classes))"
      end
    end
    if params[:user] and params[:user].length>0 then
         if params[:user].upcase=="ALL" then
           @callsign="ALL"
         else
           whereclause=whereclause+" and (callsign1='"+params[:user].upcase+"' or callsign2='"+params[:user].upcase+"')"
           @user=User.find_by(callsign: params[:user])
           if !@user then @user=current_user end
           if !@user then @user=User.first end
           @callsign=params[:user].upcase
         end
    elsif current_user then
         whereclause=whereclause+" and (user1_id='"+current_user.id.to_s+"' or user2_id='"+current_user.id.to_s+"')"
         @user=current_user
         @callsign=@user.callsign
    end
    if params[:asset] and params[:asset].length>0 then
         whereclause=whereclause+" and ('"+params[:asset].gsub('_','/')+"'=ANY(asset1_codes) or '"+params[:asset].gsub('_','/')+"'=ANY(asset2_codes))"
         @asset=Asset.find_by(code: params[:asset].upcase)
         if @asset then @assetcode=@asset.code end
    end 
    @fullcontacts=Contact.find_by_sql [ "select * from contacts where "+whereclause+" order by date desc, time desc" ]
 
    #back compatibility
    if params[:type] then params[:class]=params[:type] end
    if params[:class] and params[:class]!="all" then  
      @class=params[:class]
      as=[]
      cs=[]
      @fullcontacts.each do |contact|
        if contact.callsign2==@user.callsign then contact=contact.reverse end
        assets=Asset.assets_from_code(contact.asset1_codes.join(','))
        assets.each do |a|
          if a[:asset] and a[:type]==@class then
            contact.asset1_codes=[a[:code]]
            as.push(contact)
          end
        end
        assets=Asset.assets_from_code(contact.asset2_codes.join(','))
        assets.each do |a|
          if a[:asset] and a[:type]==@class then
            contact.asset2_codes=[a[:code]]
            cs.push(contact)
          end
        end
      end
      if params[:activator] then
        @fullcontacts=as
        @activator="on"
      elsif params[:chaser] then 
        @fullcontacts=cs
        @chaser="on"
      else 
        @fullcontacts=cs+as
      end
      @fullcontacts=@fullcontacts.uniq
    end


    if params[:pagelen] then @page_len=params[:pagelen].to_i else @page_len=20 end

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
 @contacts=(@fullcontacts||[]).paginate(:per_page => @page_len, :page => params[:page]) 
  end

  def new
     @contact=Contact.new
     if params[:spot] then
       spotid=params[:spot].to_i
       if spotid>0 then
         spot=ExternalSpot.find(spotid)
         if spot then
           @contact.callsign2=spot.activatorCallsign
           @contact.date=Time.now().in_time_zone('UTC').at_beginning_of_minute
           @contact.time=Time.now().in_time_zone('UTC').at_beginning_of_minute
           @contact.frequency=spot.frequency
           @contact.mode=spot.mode
           @contact.asset2_codes=[spot.code]
         end
       else
         spot=Post.find(-spotid)
         if spot then
           @contact.callsign2=spot.callsign
           @contact.date=Time.now().in_time_zone('UTC').at_beginning_of_minute
           @contact.time=Time.now().in_time_zone('UTC').at_beginning_of_minute
           @contact.frequency=spot.freq
           @contact.mode=spot.mode
           @contact.asset2_codes=spot.asset_codes
         end
       end
     end
     @contact.callsign1=current_user.callsign
 
  end
 
def create
  if signed_in?  then
    if params[:commit] then
      @contact = Contact.new(contact_params)
      puts ":"+params[:contact][:asset2_codes]+":"
      @contact.asset2_codes=params[:contact][:asset2_codes].gsub('[','').gsub(']','').gsub('"','').split(',')
      @contact.createdBy_id=current_user.id
      @log=@contact.create_log
      @log.save
      @contact.log_id=@log.id
      if @contact.save then
        @contact.reload
        @id=@contact.id
        params[:id]=@contact
        @user=User.find_by_callsign_date(@contact.callsign1.upcase,@contact.date)
        redirect_to '/spots'
      else
        render 'new'
      end
    else
      redirect_to '/'
    end
  else
  redirect_to '/'
  end
end
 
  def index
    @parameters=params_to_query

    index_prep()
    respond_to do |format|
      format.html
      format.js
      format.csv { send_data contacts_to_csv(@fullcontacts), filename: "contacts-#{Date.today}.csv" }
    end
  end

  def show
    @parameters=params_to_query
    if(!(@contact = Contact.find_by_id(params[:id].to_i.abs)))
      redirect_to '/'
    end
  end


 def contacts_to_csv(items)
    if signed_in? then
      require 'csv'
      csvtext=""
      if items and items.first then
        if params[:simple]=="true" then
          columns=["id","time","callsign1","asset1_codes","callsign2","asset2_codes","frequency","mode"]
        else
          columns=[]; items.first.attributes.each_pair do |name, value| if !name.include?("password") and !name.include?("digest") and !name.include?("token") then columns << name end end
          columns=columns+["place_codes1","place_codes2"]
        end
        csvtext << columns.to_csv
        items.each do |item|
           if params[:simple]=="true" then
             fields=[]; columns.each do |column| fields << item[column] end
           else
             fields=[]; item.attributes.each_pair do |name, value| if !name.include?("password") and !name.include?("digest") and !name.include?("token") then fields << value end end
             fields=fields+[item.asset1_codes, item.asset2_codes]
 

           end
           csvtext << fields.to_csv
        end
     end
     csvtext
   end
 end

  private
  def contact_params
    params.require(:contact).permit(:id, :callsign1, :user1_id, :power1, :signal1, :transceiver1, :antenna1, :comments1, :location1, :park1, :callsign2, :user2_id, :power2, :signal2, :transceiver2, :antenna2, :comments2, :hut2, :park2, :date, :time, :timezone,  :frequency, :mode, :loc_desc1, :loc_desc2, :x1, :y1, :altitude1, :location1, :x2, :y2, :altitude2, :location2, :is_active, :hut1_id, :hut2_id, :park1_id, :park2_id, :island1_id, :island2_id, :is_qrp1, :is_qrp2, :is_portable1, :is_portable2, :summit1_id, :summit2_id, :asset2_codes)
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

    else
       @contact.location2=nil
    end
  end
end
