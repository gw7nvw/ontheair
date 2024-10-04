# frozen_string_literal: true

# typed: false
class RegionsController < ApplicationController
  include ApplicationHelper

  def index
    @regions = Region.find_by_sql [' select id, name, sota_code from regions order by sota_code; ']
  end

  def show
    @section = params[:section]
    ds = Region.find_by_sql [%q{ select id, name, sota_code, sota_code, ST_Simplify("boundary",0.002) as boundary from regions where sota_code = '} + params[:id] + "';"]
    if ds
      @region = ds.first
    else
      flash[:error] = 'Region not found'
      redirect_to '/'
    end
    @assets_by_class = []
    AssetType.all.order(:name).each do |at|
      as = (Asset.find_by_sql ['select * from assets where region = ? and asset_type = ? and is_active = true and (minor != true) order by code', @region.sota_code, at.name])
      @assets_by_class.push(as) if as && (as.count > 0)
    end

    @callsign = safe_param(params[:callsign])
    @callsign = current_user.callsign if !@callsign && signed_in?

    if !@callsign || (@callsign == '/') || (@callsign == '*')
      @callsign = '*'
      @activations = User.all_activations
      @chased = User.all_chases
    else
      user = User.find_by(callsign: @callsign)
      @activations = user.activations(asset_type: 'everything', include_external: true)
      @chased = user.chased(asset_type: 'everything', include_external: true)
    end
    end
end
