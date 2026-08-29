# frozen_string_literal: true

# typed: false
class VkassetsController < ApplicationController
  include ApplicationHelper

  def index_prep
    whereclause = 'true'

    asset_type = params[:type]

    if params[:asset_type] && params[:asset_type][:to_s] && (params[:asset_type][:to_s] != '') && (params[:asset_type][:to_s] != 'All')
      asset_type = safe_param(params[:asset_type][:to_s])
    end

    whereclause += " and award = '" + asset_type + "'" if asset_type

    asset_type = 'All' if !asset_type || (asset_type == '')
    @asset_type = asset_type

    @searchtext = safe_param(params[:searchtext] || '')
    if params[:searchtext] && (params[:searchtext] != '')
      whereclause = whereclause + " and (unaccent(lower(name)) like '%%" + @searchtext.downcase + "%%' or lower(code) like '%%" + @searchtext.downcase + "%%')"
    end

    @assets = VkAsset.find_by_sql ['select id,name,code,award,state,wwff_code,pota_code from vk_assets where id in (select id from vk_assets where ' + whereclause + ' order by name limit 100) order by name']
    counts = VkAsset.find_by_sql ['select count(id) as id from vk_assets where ' + whereclause]
    # counts=0;
    @count = counts && counts.first ? counts.first.id : 0
  end

  def index
    if params[:id] then redirect_to '/vkassets/' + params[:id].tr('/', '_')
    else

      index_prep
      respond_to do |format|
        format.html
        format.js
        format.csv { send_data asset_to_csv(VkAsset.all), filename: "assets-#{Date.today}.csv" }
      end
    end
  end

  def show
    code = (params[:id] || '').tr('_', '/')
    code = code.upcase
    @asset = VkAsset.find_by(code: code)
    if @asset.nil?
      if @asset.nil?
        flash[:error] = 'Sorry - ' + code + ' does not exist in our database'
        redirect_to '/vkassets'
        return true
        end
    end
  end
end
