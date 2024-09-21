class DistrictsController < ApplicationController
include ApplicationHelper

def index
  @parameters=params_to_query
  @districts=District.find_by_sql [ " select id, name, region_code, district_code from districts order by region_code, district_code; " ]
end

def show
  @parameters=params_to_query
  @section=params[:section]
  ds=District.find_by_sql [ %q{ select id, name, region_code, district_code, ST_Simplify("boundary",0.002) as boundary from districts where district_code = '}+params[:id]+%q{';} ]
  if ds then 
    @district = ds.first 
  else 
    flash[:error]="District not found"
    redirect_to '/'
  end
  @assets_by_class=[]
  AssetType.all.order(:name).each do |at|
    as=(Asset.find_by_sql [ "select * from assets where district = ? and asset_type = ? and is_active = true and (minor = false or minor is null) order by code", @district.district_code, at.name ])
    if as and as.count>0 then @assets_by_class.push(as) end
  end

  @callsign=safe_param(params[:callsign])
  if !@callsign and signed_in? then
     @callsign=current_user.callsign
  end
  if !@callsign or @callsign=="/" then @callsign="*" end
end

end
