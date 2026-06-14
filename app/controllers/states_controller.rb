# frozen_string_literal: true

# typed: false
class StatesController < ApplicationController
  include ApplicationHelper

  def index
    dxcc = 'ZL'
    dxcc = session[:dxcc] if session[:dxcc]

    @states = State.find_by_sql [" select id, dxcc, name, code from states where dxcc='#{dxcc}' order by code; "]
  end

  def show
    @section = params[:section]
    ds = State.find_by_sql [%q{ select id, dxcc, name, code, pnp_code, ST_Simplify("boundary",0.002) as boundary from states where code = '} + params[:id] + "';"]
    ds = State.find_by_sql [%q{ select id, dxcc, name, code, pnp_code, ST_Simplify("boundary",0.002) as boundary from states where pnp_code = '} + params[:id] + "';"] if !ds or ds.count==0
    if !ds  or ds.count==0
      flash[:error] = 'State not found'
      redirect_to '/'
    else
      @state = ds.first
      @assets_by_class = []
      AssetType.all.order(:name).each do |at|
        as = (Asset.find_by_sql ['select * from assets where state = ? and asset_type = ? and is_active = true and (minor != true) order by code', @state.code, at.name])
        @assets_by_class.push(as) if as && (as.count > 0)
      end
  
      @callsign = safe_param(params[:callsign])
      @callsign = current_user.callsign if !@callsign && signed_in?
      if current_user
        if !@callsign || @callsign=="" || (@callsign == '/') || (@callsign == '*')
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
  end
end
