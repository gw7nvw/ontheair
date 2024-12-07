# frozen_string_literal: true

# typed: false
class QueryController < ApplicationController
  include ApplicationHelper

  # Returns a json list of assets based on search parameters
  # Used in find_by dialog
  # Inputs:
  #    params: 
  #       ["asset_type"]["name"]: string (AssetType.name)
  #       ["searchtext"]: string - text to match in Asset.name or Asset.code
  #       ["minor"]: boolean - EXCLUDE minor assets
  #       ["is_active"]: boolean - INCLUDE inactive assets
  #       ["assetfield"]: sting - name of field to update on parebt page with
  #                              when user selects a result from list
  # Returns:
  #   @asset_type: AssetType based on params["asset_type"]["name"] or 'All'
  #   @searchtext: params["searchtext"]
  #   @assets: Array of [Asset] matching search
  #
  # Note: results limited to first 40 matches
  def index
   
    #take search params after makeing sql-injection safe 
    @searchtext = safe_param(params[:searchtext] || '')

    #for a new search always have EXCLUDE minor enabled
    if @searchtext.blank? then
      @minor=true

    #otherwise pick up value from last search
    else
      @minor = params[:minor]? true : false
    end

    #build the query based on parameters passed
    whereclause = 'true'
    whereclause = 'is_active is true' unless params[:active]
    whereclause += ' and minor is not true' if @minor
    if params[:asset_type] && params[:asset_type][:name] && (params[:asset_type][:name] != '') && (params[:asset_type][:name] != 'all')
      whereclause += " and asset_type = '" + params[:asset_type][:name] + "'"
      asset_type = params[:asset_type][:name]
    end
    asset_type = 'all' if !asset_type || (asset_type == '')

    @asset_type = AssetType.find_by(name: asset_type)
    @assets = unless @searchtext.blank?
                Asset.find_by_sql ['select * from assets where ' + whereclause + " and (unaccent(lower(name)) like '%%" + @searchtext.downcase + "%%' or lower(code) like '%%" + @searchtext.downcase + "%%') order by name limit 40"]
              else
                []
              end
  end

  def location
    @codes = []
    @codenames = []
    x=params[:qx]
    y=params[:qy]
    if x and y then
      a=Asset.new
      a.location="POINT(#{x} #{y})"
      @codes = Asset.containing_codes_from_location(a.location, nil, true) 
      assets = Asset.assets_from_code(@codes.join(","))
      @codenames = assets.map {|a| a[:codename] }
    end
  end
end
