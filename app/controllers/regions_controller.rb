class RegionsController < ApplicationController
include ApplicationHelper


def index
  @parameters=params_to_query
  @regions=Region.find_by_sql [ " select id, name, sota_code from regions order by sota_code; " ]
end

def show
  @parameters=params_to_query
  @section=params[:section]
  ds=Region.find_by_sql [ %q{ select id, name, sota_code, sota_code, ST_Simplify("boundary",0.002) as boundary from regions where sota_code = '}+params[:id]+%q{';} ]
  if ds then 
    @region = ds.first 
  else 
    flash[:error]="Region not found"
    redirect_to '/'
  end
  @assets_by_class=[]
  AssetType.all.order(:name).each do |at|
    as=(Asset.find_by_sql [ "select * from assets where region = ? and asset_type = ? and is_active = true and (minor != true) order by code", @region.sota_code, at.name ])
    if as and as.count>0 then @assets_by_class.push(as) end
  end

  @callsign=safe_param(params[:callsign])
  if !@callsign and signed_in? then
     @callsign=current_user.callsign
  end
  if !@callsign or @callsign=="/" then @callsign="*" end
end

end
