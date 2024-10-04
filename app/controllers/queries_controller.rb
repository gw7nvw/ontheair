# frozen_string_literal: true

# typed: false
class QueriesController < ApplicationController
  skip_before_action :verify_authenticity_token

  def asset
    query = params[:query]
    asset_type = params[:asset_type]
    assets = if asset_type && !asset_type.empty? && (asset_type != 'all')
               Asset.find_by_sql ["select code,name from assets where is_active=true and (minor is null or minor=false) and (unaccent(name) ilike '%%" + query + "%%' or code ilike '%%" + query + "%%') and asset_type='" + asset_type + "' order by name"]

             else
               Asset.find_by_sql ["select code,name from assets where is_active=true and (minor is null or minor=false) and (unaccent(name) ilike '%%" + query + "%%' or code ilike '%%" + query + "%%') order by name"]
             end
    render json: assets.map(&:codename)
  end

  def test
    puts request.raw_post
  end
end
