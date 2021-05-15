class ApiController < ApplicationController

def index

end


def assettype
    respond_to do |format|
      format.js { render json: AssetType.all.to_json}
      format.html { render json: AssetType.all.to_json}
      format.csv { send_data asset_to_csv(AssetType.all), filename: "assets-#{Date.today}.csv" }
    end
end

def asset
    whereclause="true"

    if not params[:is_active] then
      whereclause="is_active is true"
    end

    if not params[:minor] then
      whereclause+=" and minor is not true"
    end

    if params[:asset_type] and params[:asset_type]!='' and params[:asset_type]!='all' then
      asset_type=params[:asset_type]
    end

    if params[:updated_since] then 
      whereclause+=" and updated_at > '"+params[:updated_since]+"'"
    end

    if asset_type then
      whereclause+=" and asset_type = '"+asset_type+"'"
    end

    @searchtext=params[:searchtext] || ""
    if params[:searchtext] then
       whereclause=whereclause+" and (lower(name) like '%%"+@searchtext.downcase+"%%' or lower(code) like '%%"+@searchtext.downcase+"%%')"
    end


    @assets=Asset.find_by_sql [ "select id, asset_type, code, name,location,minor,is_active,created_at, updated_at from assets where "+whereclause ] 

    respond_to do |format|
      format.js { render json: @assets.to_json}
      format.html { render json: @assets.to_json}
      format.csv { send_data asset_to_csv(@assets), filename: "assets-#{Date.today}.csv" }
    end

end

end