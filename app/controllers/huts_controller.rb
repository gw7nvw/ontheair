class HutsController < ApplicationController
  before_action :signed_in_user, only: [:edit, :update, :editgrid]

  def editgrid

  end

  def index_prep
    whereclause="true"
    if params[:filter] then
      @filter=params[:filter]
      whereclause="is_"+@filter+" is true"
    end
    
    @searchtext=params[:searchtext]
    if params[:searchtext] then
       whereclause=whereclause+" and (lower(name) like '%%"+@searchtext.downcase+"%%' or CONCAT('zlh/',LPAD(id::text, 4, '0')) like '%%"+@searchtext.downcase+"%%')"
    end

    @huts=Hut.find_by_sql [ 'select * from huts where '+whereclause+' order by name limit 100' ]
    counts=Hut.find_by_sql [ 'select count(id) as id from huts where '+whereclause ]
    if counts and counts.first then @count=counts.first.id else @count=0 end
    @users=User.where("huts_bagged is not null and huts_bagged>0").order(:huts_bagged).reverse 

  end


  def index
    index_prep()
    respond_to do |format|
      format.html
      format.js
      format.csv { send_data huts_to_csv(Hut.all), filename: "huts-#{Date.today}.csv" }
    end
  end

  def show
    if(!(@hut = Hut.find_by_id(params[:id].to_i)))
      redirect_to '/'
    end
  end

  def edit
    if params[:referring] then @referring=params[:referring] end

    if(!(@hut = Hut.where(id: params[:id]).first))
      redirect_to '/'
    end
    if(@hut.location==nil and @hut.x and @hut.y) then
      convert_location_params()
    end
  end
  def new
    @hut = Hut.new
  end

 def create
    if signed_in? and current_user.is_modifier then

    @hut = Hut.new(hut_params)

    convert_location_params()

    #assign a hut
    if not @hut.park_id then
      p=@hut.find_doc_park
      if not p then 
        p=@hut.find_park
      end
      if p then @hut.park_id=p.id end
    end
    @hut.createdBy_id=current_user.id

      if @hut.save
          @hut.reload
          @hut.find_hutbagger_photos
          if params[:referring]=='index' then
            index_prep()
            render 'index'
          else
            render 'show'
          end

      else
          render 'new'
      end
    else
      redirect_to '/'
    end
 end

 def update
  if signed_in? and current_user.is_modifier then
    if params[:delete] then
      hut = Hut.find_by_id(params[:id])
      if hut and hut.destroy
        flash[:success] = "Hut deleted, id:"+params[:id]
        index_prep()
        render 'index'
      else
        edit()
        render 'edit'
      end
    else
      if(!@hut = Hut.find_by_id(params[:id]))
          flash[:error] = "Hut does not exist: "+@hut.id.to_s

          #tried to update a nonexistant hut
          render 'edit'
      end

      @hut.assign_attributes(hut_params)
      convert_location_params()
      #assign a hut
      if not @hut.park_id then
        p=@hut.find_doc_park
        if not p then 
          p=@hut.find_park
        end
        if p then @hut.park_id=p.id end
      end
      @hut.createdBy_id=current_user.id

      if @hut.save
        flash[:success] = "Hut details updated"
        @hut.find_hutbagger_photos
        # Handle a successful update.
        if params[:referring]=='index' then
          index_prep()
          render 'index'
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
#editgrid handlers

  def data
            huts = Hut.all.order(:name)

            render :json => {
                 :total_count => huts.length,
                 :pos => 0,
                 :rows => huts.map do |hut|
                 {
                   :id => hut.id,
                   :data => [hut.id, hut.name,  hut.description, hut.x, hut.y, hut.altitude, hut.is_active, hut.is_doc, hut.hutbagger_link, hut.doc_link, hut.tramper_link, hut.routeguides_link, hut.general_link]
                 }
                 end
            }
  end
def db_action
  if signed_in? and current_user.is_modifier then
    @mode = params["!nativeeditor_status"]
    id = params['c0']
    name = params['c1']
    description = params['c2']
    x = params['c3']
    y = params['c4']
    altitude = params['c5']
    is_active = params['c6']
    is_doc = params['c7']
    hutbagger_link = params['c8']
    doc_link = params['c9']
    tramper_link = params['c10']
    routeguides_link = params['c11']
    general_link = params['c12']

    @id = params["gr_id"]

    case @mode
    when "inserted"
        hut = Hut.create :name => name,:description => description, :x => x, :y => y, :altitude => altitude, :is_active => is_active, :is_doc => is_doc, :hutbagger_link => hutbagger_link, :doc_link => doc_link, :tramper_link => tramper_link, :routeguides_link => routeguides_link, :general_link => general_link
       if hut then
          @tid = hut.id
       else
          @mode="error"
          @tid=nil
       end

    when "deleted"
        if Hut.find(@id).destroy then
          @tid = @id
        else
          @mode-"error"
          @tid=nil
       end

    when "updated"
        @hut = Hut.find(@id)
        if @hut.x!=x or @hut.y!=y then need_convert=true else need_convert=false end
        @hut.name = name
        @hut.description = description
        if x!="" then @hut.x = x else @hut.x = nil end
        if y!="" then @hut.y = y else @hut.y = nil end
        @hut.altitude = altitude
        @hut.is_active = is_active
        @hut.is_doc = is_doc
        @hut.tramper_link = tramper_link
        @hut.doc_link = doc_link
        @hut.hutbagger_link = hutbagger_link
        @hut.routeguides_link = routeguides_link
        @hut.general_link = general_link

        if need_convert then convert_location_params() end
        if @hut.x and @hut.y then
          @hut.x = @hut.x.to_i
          @hut.y = @hut.y.to_i
        end
        if !@hut.save then @mode="error" end

        @tid = @id
    end

  end
end

  def huts_to_csv(items)
      require 'csv'
      csvtext=""
      if items and items.first then
        columns=["code"]; items.first.attributes.each_pair do |name, value| if !name.include?("password") and !name.include?("digest") and !name.include?("token") and !name.include?("_link") then columns << name end end
        csvtext << columns.to_csv
        items.each do |item|
           fields=[item.code]; item.attributes.each_pair do |name, value| if !name.include?("password") and !name.include?("digest") and !name.include?("token") and !name.include?("_link") then fields << value end end
           csvtext << fields.to_csv
        end
     end
     csvtext
  end

  private
  def hut_params
    params.require(:hut).permit(:id, :name, :description, :x, :y, :altitude, :hutbagger_link, :tramper_link, :doc_link, :routeguides_link, :general_link, :is_active, :is_doc, :park_id)
  end

  def convert_location_params
   if(@hut.x and @hut.y)


       # convert to WGS84 (EPSG4326) for database 
       fromproj4s= Projection.find_by_id(2193).proj4
       toproj4s=  Projection.find_by_id(4326).proj4

       fromproj=RGeo::CoordSys::Proj4.new(fromproj4s)
       toproj=RGeo::CoordSys::Proj4.new(toproj4s)

       xyarr=RGeo::CoordSys::Proj4::transform_coords(fromproj,toproj,@hut.x,@hut.y)

       params[:location]=xyarr[0].to_s+" "+xyarr[1].to_s
       @hut.location='POINT('+params[:location]+')'

      #if altitude is not entered, calculate it from map 
      if !@hut.altitude or @hut.altitude.to_i == 0 then
         #get alt from map if it is blank or 0
         altArr=Dem30.find_by_sql ["
            select ST_Value(rast, ST_GeomFromText(?,4326))  rid
               from dem30s
               where ST_Intersects(rast,ST_GeomFromText(?,4326));",
               'POINT('+params[:location]+')',
               'POINT('+params[:location]+')']

         @hut.altitude=altArr.first.try(:rid).to_i
       end
    else
       @hut.location=nil
    end
  end


end

