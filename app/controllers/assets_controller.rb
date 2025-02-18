# frozen_string_literal: true

# typed: false
class AssetsController < ApplicationController
  include PostsHelper
  include ApplicationHelper
  include AssetGisTools

  before_action :signed_in_user, only: %i[edit update create new associations]

  def associations
    @asset=Asset.find_by(code: params[:id].gsub('_','/'))
    if @asset.nil?
      flash[:error] = 'Sorry - ' + code + ' does not exist in our database'
      redirect_to '/assets'
      return true
    else
      @newchild=AssetLink.new
      @newchild.contained_code=@asset.code
      @newparent=AssetLink.new
      @newparent.containing_code=@asset.code
    end
  end

  def index_prep
    whereclause = 'true'

    whereclause = 'is_active is true' unless params[:active]

    whereclause += ' and minor is not true' if params[:minor]
    asset_type = params[:type]

    if params[:asset_type] && params[:asset_type][:name] && (params[:asset_type][:name] != '') && (params[:asset_type][:name] != 'all')
      asset_type = params[:asset_type][:name]
    end

    whereclause += " and asset_type = '" + asset_type + "'" if asset_type

    asset_type = 'all' if !asset_type || (asset_type == '')
    @asset_type = AssetType.find_by(name: safe_param(asset_type))

    @searchtext = safe_param(params[:searchtext] || '')
    unless @limit
      if params[:searchtext] && (params[:searchtext] != '')
        @limit = 500 # 100
        whereclause = whereclause + " and (unaccent(lower(name)) like '%%" + @searchtext.downcase + "%%' or lower(code) like '%%" + @searchtext.downcase + "%%' or lower(old_code) like '%%" + @searchtext.downcase + "%%')"
      else
        @limit = 500 # 20
      end
    end

    @fullassets = Asset.find_by_sql ['select id,name,code,asset_type,url,is_active,safecode,category,minor,district,region,altitude,location,description from assets where id in (select id from assets where ' + whereclause + " order by name limit #{@limit}) order by name"]
    @assets = @fullassets.paginate(per_page: 40, page: params[:page])
    counts = Asset.find_by_sql ['select count(id) as id from assets where ' + whereclause]
    # @count=0;
    @count = counts && counts.first ? counts.first.id : 0
  end

  def index
    if params[:id] then redirect_to '/assets/' + params[:id].tr('/', '_')
    else

      @limit = 30_000 if request.path.match('gpx') || request.path.match('csv')

      index_prep
      respond_to do |format|
        format.html
        format.js
        format.csv { send_data asset_to_csv(@fullassets), filename: "assets-#{Date.today}.csv" }
        format.gpx { send_data asset_to_gpx(@fullassets), filename: "assets-#{Date.today}.gpx" }
      end
    end
  end

  def refresh_pota
    if signed_in?
      a = Asset.find_by(safecode: params[:id])
      if a && (a.asset_type == 'pota park')
        ExternalActivation.update_pota_activation(a)
      end
    else
      flash[:error] = 'You must be signed in to do this'
    end
    redirect_to '/assets/' + params[:id]
  end

  def refresh_sota
    if signed_in?
      a = Asset.find_by(safecode: params[:id])
      if a && (a.asset_type == 'summit')
        ExternalActivation.update_sota_activation(a)
      end
    else
      flash[:error] = 'You must be signed in to do this'
    end

    redirect_to '/assets/' + params[:id]
  end

  def show
    @newlink = AssetWebLink.new
    code = (params[:id] || '').tr('_', '/')
    code = code.upcase
    @asset = Asset.find_by(code: code)
    if @asset.nil?
      @asset = Asset.find_by(old_code: code)
      if @asset.nil?
        flash[:error] = 'Sorry - ' + code + ' does not exist in our database'
        redirect_to '/assets'
        return true
      end
    end
    @newlink.asset_code = @asset.safecode
    @comments = Comment.for_asset(code)
  end

  def edit
    if signed_in? && current_user.is_modifier
      @referring = params[:referring] if params[:referring]

      unless (@asset = Asset.where(code: params[:id].tr('_', '/')).first)
        flash[:error] = 'Asset not found'
        redirect_to '/assets'
      end
    else
      flash[:error] = 'You do not have permissions to create a new asset'
      redirect_to '/assets'
    end
  end

  def new
    if signed_in? && current_user.is_modifier
      @asset = Asset.new
    else
      flash[:error] = 'You do not have permissions to create a new asset'
      redirect_to '/assets'
    end
  end

  def create
    if signed_in? && current_user.is_modifier
      @asset = Asset.new(asset_params)

      convert_location_params(params[:asset][:x], params[:asset][:y])
      @asset.boundary=make_multipolygon(params[:asset][:boundary]) if params[:asset][:boundary]

      @asset.createdBy_id = current_user.id
      @asset.region = @asset.add_region unless @asset.region
      if @asset.code.nil? || (@asset.code == '') then @asset.code = Asset.get_next_code(@asset.asset_type, @asset.region) end
      if @asset.save
        @asset.reload
        flash[:success] = 'Success!'
        if params[:referring] == 'index'
          index_prep
          render 'index'
        else
          redirect_to '/assets/' + @asset.safecode
        end
      else
        render 'new'
      end
    else
      flash[:error] = 'You do not have permissions to create a new asset'
      redirect_to '/assets'
    end
  end

  def update
    if signed_in? && current_user.is_modifier
      if params[:delete]
        asset = Asset.find_by_id(params[:id])
        if asset
          als = AssetLink.where(contained_code: asset.code)
          als.destroy_all
          als = AssetLink.where(containing_code: asset.code)
          als.destroy_all
          als = AssetWebLink.where(asset_code: asset.code)
          als.destroy_all
        end

        if asset && asset.destroy
          index_prep
          flash[:success] = 'Asset deleted, id:' + params[:id]
          redirect_to '/assets'
        else
          edit
          flash[:error] = 'Failed to delete asset, id:' + params[:id]
          render 'edit'
        end
      elsif !@asset = Asset.find_by_id(params[:id])
        flash[:error] = 'Asset not found: ' + params[:id]

        # tried to update a nonexistant asset
        redirect_to '/assets'
      else

        @asset.assign_attributes(asset_params)
        convert_location_params(params[:asset][:x], params[:asset][:y])
        @asset.boundary=make_multipolygon(params[:asset][:boundary]) if params[:asset][:boundary]

        # assign a asset
        @asset.createdBy_id = current_user.id

        if @asset.save
          flash[:success] = 'Asset details updated'
          # Handle a successful update.
          if params[:referring] == 'index'
            index_prep
            render 'index'
          else
            redirect_to '/assets/' + @asset.safecode
          end
        else
          render 'edit'
        end
      end
    else
      flash[:error] = 'You do not have permissions to update an asset'
      redirect_to '/assets'
    end
  end

  private

  def asset_params
    params.require(:asset).permit(:id, :name, :description, :altitude, :is_active, :is_nzart, :minor, :is_doc, :park_id, :asset_type, :code, :valid_from, :valid_to, :az_radius, :points, :public_access, :region, :district, :field_code)
  end

  def convert_location_params(x, y)
    # convert to WGS84 (EPSG4326) for database
    fromproj4s = Projection.find_by_id(2193).proj4
    toproj4s = Projection.find_by_id(4326).proj4

    fromproj = RGeo::CoordSys::Proj4.new(fromproj4s)
    toproj = RGeo::CoordSys::Proj4.new(toproj4s)

    xyarr = RGeo::CoordSys::Proj4.transform_coords(fromproj, toproj, x.to_f, y.to_f)

    params[:location] = xyarr[0].to_s + ' ' + xyarr[1].to_s
    @asset.location = 'POINT(' + params[:location] + ')'
  end
end
