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

    if params[:user] and params[:user].length>0 then
         whereclause=whereclause+" and (callsign1='"+params[:user]+"' or callsign2='"+params[:user]+"')"
         @user=User.find_by(callsign: params[:user])
         @callsign=params[:user].upcase
    elsif current_user then
         whereclause=whereclause+" and (callsign1='"+current_user.callsign+"' or callsign2='"+current_user.callsign+"')"
         @user=current_user
    end
    if params[:asset] and params[:asset].length>0 then
         whereclause=whereclause+" and ('"+params[:asset].gsub('_','/')+"'=ANY(asset1_codes) or '"+params[:asset].gsub('_','/')+"'=ANY(asset2_codes))"
         @asset=Asset.find_by(code: params[:asset].upcase)
         if @asset then @assetcode=@asset.code end
    end 
    @fullcontacts=Contact.find_by_sql [ "select * from contacts where "+whereclause+" order by date desc, time desc" ]
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
 @contacts=(@fullcontacts||[]).paginate(:per_page => 20, :page => params[:page]) 
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
        columns=[]; items.first.attributes.each_pair do |name, value| if !name.include?("password") and !name.include?("digest") and !name.include?("token") then columns << name end end
        columns=columns+["place_codes1","place_codes2"]
        csvtext << columns.to_csv
        items.each do |item|
           fields=[]; item.attributes.each_pair do |name, value| if !name.include?("password") and !name.include?("digest") and !name.include?("token") then fields << value end end
           fields=fields+[item.asset1_codes, item.asset2_codes]
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
