class AssetsController < ApplicationController
  before_action :signed_in_user, only: [:edit, :update, :editgrid]


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
    if params[:searchtext] then
       whereclause=whereclause+" and (lower(name) like '%%"+@searchtext.downcase+"%%' or lower(code) like '%%"+@searchtext.downcase+"%%')"
    end

    @assets=Asset.find_by_sql [ 'select * from assets where '+whereclause+' order by name limit 100' ]
    counts=Asset.find_by_sql [ 'select count(id) as id from assets where '+whereclause ]
    if counts and counts.first then @count=counts.first.id else @count=0 end
    #@users=User.where("assets_bagged is not null and assets_bagged>0").order(:assets_bagged).reverse 

  end


  def index
    @parameters=params_to_query

    index_prep()
    respond_to do |format|
      format.html
      format.js
      format.csv { send_data asset_to_csv(Asset.all), filename: "assets-#{Date.today}.csv" }
    end
  end

  def show
    @newlink=AssetWebLink.new
    @parameters=params_to_query
    code=params[:id].gsub("_","/")
    if(!(@asset = Asset.find_by(code: code)))
      redirect_to '/'
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
    if @asset.code==nil or @asset.code=="" then   @asset.code=Asset.get_next_code(@asset.asset_type) end
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

  def assets_to_csv(items)
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
    params.require(:asset).permit(:id, :name, :description, :altitude, :assetbagger_link, :tramper_link, :doc_link, :routeguides_link, :general_link, :is_active, :is_doc, :park_id, :asset_type, :code)
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

