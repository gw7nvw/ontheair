class AssetsController < ApplicationController
  before_action :signed_in_user, only: [:edit, :update, :create, :new]


  def index_prep

    whereclause="true"

    if not params[:active] then
      whereclause="is_active is true"
    end

    if not params[:minor] then
      whereclause+=" and minor is not true"
    end
    asset_type=params[:type]

    if params[:asset_type] and params[:asset_type][:name] and params[:asset_type][:name]!='' and params[:asset_type][:name]!='all' then 
      asset_type=params[:asset_type][:name]    
    end

    if asset_type then
      whereclause+=" and asset_type = '"+asset_type+"'"
    end

    if !asset_type or asset_type=="" then asset_type="all" end
    @asset_type=AssetType.find_by(name: asset_type)

    @searchtext=params[:searchtext] || ""
    if params[:searchtext] and params[:searchtext]!="" then
       @limit=100
       whereclause=whereclause+" and (unaccent(lower(name)) like '%%"+@searchtext.downcase+"%%' or lower(code) like '%%"+@searchtext.downcase+"%%')"
    else
       @limit=20
    end

    @assets=Asset.find_by_sql [ "select id,name,code,asset_type,url,is_active,safecode,category,minor,description,region from assets where id in (select id from assets where "+whereclause+" order by name limit #{@limit}) order by name" ]
    counts=Asset.find_by_sql [ 'select count(id) as id from assets where '+whereclause ]
    #counts=0;
    if counts and counts.first then @count=counts.first.id else @count=0 end

  end


  def index

    if params[:id] then redirect_to '/assets/'+params[:id].gsub('/','_')
    else

    @parameters=params_to_query

    index_prep()
    respond_to do |format|
      format.html
      format.js
      format.csv { send_data asset_to_csv(Asset.all), filename: "assets-#{Date.today}.csv" }
    end
    end
  end

  def refresh_pota
    if signed_in? then
      a=Asset.find_by(safecode: params[:id])
      if a and a.asset_type=='pota park' then
        SotaActivation.update_pota_activation(a)
      end
    else 
      flash[:error]="You must be signed in to do this"
    end
    redirect_to '/assets/'+params[:id]
  end

  def refresh_sota
    if signed_in? then
      a=Asset.find_by(safecode: params[:id])
      if a and a.asset_type=='summit' then
        SotaActivation.update_sota_activation(a)
      end
    else
      flash[:error]="You must be signed in to do this"
    end

    redirect_to '/assets/'+params[:id]
  end

  def show
    @newlink=AssetWebLink.new
    @parameters=params_to_query
    code=(params[:id]||"").gsub("_","/")
    code=code.upcase
    @asset = Asset.find_by(code: code)
    if(@asset==nil) then
        @asset = Asset.find_by(old_code: code)
        if(@asset==nil) then
          flash[:error]="Sorry - "+code+" does not exist in our database"
          redirect_to '/assets'
          return true
        end
    end
    @newlink.asset_code=@asset.safecode
  end

  def edit
    if params[:referring] then @referring=params[:referring] end

    if(!(@asset = Asset.where(code: params[:id].gsub("_","/")).first))
      redirect_to '/'
    end
  end
  def new
    @parameters=params_to_query
    @asset = Asset.new
  end

 def create
	    if signed_in? and current_user.is_modifier then

    @asset = Asset.new(asset_params)

    convert_location_params(params[:asset][:x], params[:asset][:y])

    @asset.createdBy_id=current_user.id
    if !@asset.region then @asset.region=@asset.add_region end
    if @asset.code==nil or @asset.code=="" then   @asset.code=Asset.get_next_code(@asset.asset_type, @asset.region) end
      if @asset.save
          @asset.reload
          @asset.find_hutbagger_photos
          if params[:referring]=='index' then
            index_prep()
            render 'index'
          else
            redirect_to '/assets/'+@asset.safecode
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
      asset = Asset.find_by_id(params[:id])
      als=AssetLink.where(parent_code: asset.code)
      als.destroy_all
      als=AssetLink.where(child_code: asset.code)
      als.destroy_all

      if asset and asset.destroy
        flash[:success] = "Asset deleted, id:"+params[:id]
        index_prep()
        render 'index'
      else
        edit()
        render 'edit'
      end
    else
      if(!@asset = Asset.find_by_id(params[:id]))
          flash[:error] = "Asset does not exist: "+@asset.id.to_s

          #tried to update a nonexistant asset
          render 'edit'
      end

      @asset.assign_attributes(asset_params)
      convert_location_params(params[:asset][:x], params[:asset][:y])
      #assign a asset
      @asset.createdBy_id=current_user.id

      if @asset.save
        flash[:success] = "Asset details updated"
        @asset.find_hutbagger_photos
        # Handle a successful update.
        if params[:referring]=='index' then
          index_prep()
          render 'index'
        else
          redirect_to '/assets/'+@asset.safecode
        end
      else
        render 'edit'
      end
    end
  else
    redirect_to '/'
  end
end

def associations
  @asset=Asset.find_by(code: params[:id].gsub('_','/'))
  @newchild=AssetLink.new
  @newchild.parent_code=@asset.code
  @newparent=AssetLink.new
  @newparent.child_code=@asset.code

end

  def asset_to_csv(items)
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
  def asset_params
    params.require(:asset).permit(:id, :name, :description, :altitude, :is_active, :minor, :is_doc, :park_id, :asset_type, :code)
  end

  def convert_location_params(x,y)


       # convert to WGS84 (EPSG4326) for database 
       fromproj4s= Projection.find_by_id(2193).proj4
       toproj4s=  Projection.find_by_id(4326).proj4

       fromproj=RGeo::CoordSys::Proj4.new(fromproj4s)
       toproj=RGeo::CoordSys::Proj4.new(toproj4s)

       xyarr=RGeo::CoordSys::Proj4::transform_coords(fromproj,toproj,x.to_f,y.to_f)

       params[:location]=xyarr[0].to_s+" "+xyarr[1].to_s
       @asset.location='POINT('+params[:location]+')'

      #if altitude is not entered, calculate it from map 
      if !@asset.altitude or @asset.altitude.to_i == 0 then
         #get alt from map if it is blank or 0
         altArr=Dem30.find_by_sql ["
            select ST_Value(rast, ST_GeomFromText(?,4326))  rid
               from dem30s
               where ST_Intersects(rast,ST_GeomFromText(?,4326));",
               'POINT('+params[:location]+')',
               'POINT('+params[:location]+')']

         @asset.altitude=altArr.first.try(:rid).to_i
       end
  end


end

