# frozen_string_literal: true

# typed: false
class DistrictsController < ApplicationController
  include ApplicationHelper

  def index
    @districts = District.find_by_sql [' select id, name, region_code, district_code from districts order by region_code, district_code; ']
  end

  def show
    @section = params[:section]
    ds = District.find_by_sql [%q{ select id, name, region_code, district_code, ST_Simplify("boundary",0.002) as boundary from districts where district_code = '} + params[:id] + "';"]
    if ds
      @district = ds.first
    else
      flash[:error] = 'District not found'
      redirect_to '/'
    end
    @assets_by_class = []
    AssetType.all.order(:name).each do |at|
      as = (Asset.find_by_sql ['select * from assets where district = ? and asset_type = ? and is_active = true and (minor = false or minor is null) order by code', @district.district_code, at.name])
      @assets_by_class.push(as) if as && (as.count > 0)
    end

    @callsign = safe_param(params[:callsign])
    @callsign = current_user.callsign if !@callsign && signed_in?
    @callsign = '*' if !@callsign || (@callsign == '/')
  end
end
