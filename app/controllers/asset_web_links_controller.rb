# frozen_string_literal: true

# typed: false
class AssetWebLinksController < ApplicationController
  before_action :signed_in_user

  def create
    if signed_in?
      if Asset.find_by(code: params[:asset_web_link][:asset_code].tr('_', '/'))
        if awl = AssetWebLink.create(asset_web_link_params)
          awl.asset_code = awl.asset_code.tr('_', '/')
          awl.url = 'http://' + awl.url if awl.url[0..3] != 'http'
          awl.save
          flash[:success] = 'Link created'
        else
          flash[:error] = 'Could not create link'
        end
        asset_code = awl.asset_code
        if asset_code
          redirect_to '/assets/' + asset_code.tr('/', '_')
        else
          redirect_to '/'
        end
      else
        flash[:error] = 'Asset not found'
        redirect_to '/'
      end
    else
      flash[:error] = 'You must be logged in to create links'
      redirect_to '/'
    end
  end

  def delete
    if signed_in?
      awl = AssetWebLink.find_by(id: params[:id])
      if awl && awl.destroy
        flash[:success] = 'Link deleted'
      else
        flash[:error] = 'Failed to delete link'
      end
      if awl && awl.asset_code
        redirect_to '/assets/' + awl.asset_code.tr('/', '_')
      else
        redirect_to '/'
      end
    else
      flash[:error] = 'You must be logged in to delete this link'
      redirect_to '/'
    end
  end

  private

  def asset_web_link_params
    params.require(:asset_web_link).permit(:id, :link_class, :asset_code, :url)
  end
end
