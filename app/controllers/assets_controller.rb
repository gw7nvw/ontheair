# typed: false
class AssetsController < ApplicationController
include PostsHelper
include ApplicationHelper

  before_action :signed_in_user, only: [:edit, :update, :create, :new]


  def index_prep
    whereclause="true"

    if not params[:active] then
      whereclause="is_active is true"
    end

    if params[:minor] then
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
    @asset_type=AssetType.find_by(name: safe_param(asset_type))

    @searchtext=safe_param(params[:searchtext] || "")
    if !@limit then  
    if params[:searchtext] and params[:searchtext]!="" then
       @limit=500 #100
       whereclause=whereclause+" and (unaccent(lower(name)) like '%%"+@searchtext.downcase+"%%' or lower(code) like '%%"+@searchtext.downcase+"%%' or lower(old_code) like '%%"+@searchtext.downcase+"%%')"
    else
       @limit=500 #20
    end
    end

    @fullassets=Asset.find_by_sql [ "select id,name,code,asset_type,url,is_active,safecode,category,minor,district,region,altitude,location,description from assets where id in (select id from assets where "+whereclause+" order by name limit #{@limit}) order by name" ]
    @assets=@fullassets.paginate(:per_page => 40, :page => params[:page])
    counts=Asset.find_by_sql [ 'select count(id) as id from assets where '+whereclause ]
    #@count=0;
    if counts and counts.first then @count=counts.first.id else @count=0 end

  end


  def index
    if params[:id] then redirect_to '/assets/'+params[:id].gsub('/','_')
    else

    @parameters=params_to_query
    if request.path.match('gpx') or request.path.match('csv') then @limit=30000 end

    index_prep()
    respond_to do |format|
      format.html
      format.js
      format.csv { send_data asset_to_csv(@fullassets), filename: "assets-#{Date.today}.csv" }
      format.gpx { send_data asset_to_gpx(@fullassets), filename: "assets-#{Date.today}.gpx" }
    end
    end
  end

  def refresh_pota
    if signed_in? then
      a=Asset.find_by(safecode: params[:id])
      if a and a.asset_type=='pota park' then
        ExternalActivation.update_pota_activation(a)
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
        ExternalActivation.update_sota_activation(a)
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
    @comments=Comment.for_asset(code)
  end

  def edit
    if signed_in? and current_user.is_modifier then
      if params[:referring] then @referring=params[:referring] end

      if(!(@asset = Asset.where(code: params[:id].gsub("_","/")).first))
        flash[:error]="Asset not found"
        redirect_to '/assets'
      end
    else
      flash[:error]="You do not have permissions to create a new asset"
      redirect_to '/assets'
    end
  end

  def new
    if signed_in? and current_user.is_modifier then
      @parameters=params_to_query
      @asset = Asset.new
    else
      flash[:error]="You do not have permissions to create a new asset"
      redirect_to '/assets'
    end
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
        flash[:success]="Success!"
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
      flash[:error]="You do not have permissions to create a new asset"
      redirect_to '/assets'
    end
  end

  def update
    if signed_in? and current_user.is_modifier then
      if params[:delete] then
        asset = Asset.find_by_id(params[:id])
        if asset
          als=AssetLink.where(contained_code: asset.code)
          als.destroy_all
          als=AssetLink.where(containing_code: asset.code)
          als.destroy_all
          als=AssetWebLink.where(asset_code: asset.code)
          als.destroy_all
        end

        if asset and asset.destroy
          index_prep()
          flash[:success] = "Asset deleted, id:"+params[:id]
          redirect_to '/assets'
        else
          edit()
          flash[:error] = "Failed to delete asset, id:"+params[:id]
          render 'edit'
        end
      else
        if(!@asset = Asset.find_by_id(params[:id]))
          flash[:error] = "Asset not found: "+params[:id]

          #tried to update a nonexistant asset
          redirect_to '/assets'
        else

          @asset.assign_attributes(asset_params)
          convert_location_params(params[:asset][:x], params[:asset][:y])
          #assign a asset
          @asset.createdBy_id=current_user.id
    
          if @asset.save
            flash[:success] = "Asset details updated"
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
      end
    else
      flash[:error]="You do not have permissions to update an asset"
      redirect_to '/assets'
    end
  end


  private
  def asset_params
    params.require(:asset).permit(:id, :name, :description, :altitude, :is_active, :is_nzart, :minor, :is_doc, :park_id, :asset_type, :code, :valid_from, :valid_to, :az_radius, :points, :public_access, :region, :district)
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

  end

end

