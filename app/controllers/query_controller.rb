# frozen_string_literal: true

# typed: false
class QueryController < ApplicationController
  def index
    asset_type = params[:type]
    whereclause = 'true'
    whereclause = 'is_active is true' unless params[:active]
    whereclause += ' and minor is not true' if params[:minor]
    if params[:asset_type] && params[:asset_type][:name] && (params[:asset_type][:name] != '') && (params[:asset_type][:name] != 'all')
      whereclause += " and asset_type = '" + params[:asset_type][:name] + "'"
      asset_type = params[:asset_type][:name]
    end
    asset_type = 'all' if !asset_type || (asset_type == '')
    @asset_type = AssetType.find_by(name: asset_type)

    @searchtext = params[:searchtext]
    @assets = if @searchtext
                Asset.find_by_sql ['select * from assets where ' + whereclause + " and (unaccent(lower(name)) like '%%" + @searchtext.downcase + "%%' or lower(code) like '%%" + @searchtext.downcase + "%%') order by name limit 40"]
              else
                []
              end
    end
end
