# typed: false
class QueryController < ApplicationController

def index
  asset_type=params[:type]
  whereclause="true"
  if not params[:active] then
    whereclause="is_active is true"
  end
  if params[:minor] then
    whereclause+=" and minor is not true"
  end
  if params[:asset_type] and params[:asset_type][:name] and params[:asset_type][:name]!='' and params[:asset_type][:name]!='all' then
    whereclause+=" and asset_type = '"+params[:asset_type][:name]+"'"
    asset_type=params[:asset_type][:name]
  end
  if !asset_type or asset_type=="" then asset_type="all" end
  @asset_type=AssetType.find_by(name: asset_type)

  @searchtext=params[:searchtext]
  if @searchtext then
     @assets=Asset.find_by_sql [ "select * from assets where "+whereclause+" and (unaccent(lower(name)) like '%%"+@searchtext.downcase+"%%' or lower(code) like '%%"+@searchtext.downcase+"%%') order by name limit 40"]
  else
     @assets=[]
  end

end

end
