# frozen_string_literal: true

# typed: false
class AssetLinksController < ApplicationController
  before_action :signed_in_user

  def create
    if signed_in?
      if (ca = Asset.find_by(code: params[:asset_link][:containing_code].tr('_', '/'))) &&
         (cp = Asset.find_by(code: params[:asset_link][:contained_code].tr('_', '/')))
        if (awl = AssetLink.create(containing_code: ca.code, contained_code: cp.code))
          awl.save
          flash[:success] = 'Link created'
        else
          flash[:error] = 'Could not create link'
        end

        asset_code = params[:asset_code]
        if asset_code
          redirect_to '/assets/' + asset_code.tr('/', '_') + '/associations'
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
      awl = AssetLink.find_by(id: params[:id])
      asset_code = params[:asset_code]
      if awl && awl.destroy
        flash[:success] = 'Link deleted'
      else
        flash[:error] = 'Failed to delete link'
      end
      if asset_code
        redirect_to '/assets/' + asset_code.tr('/', '_') + '/associations'
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
    params.require(:asset_web_link).permit(:containing_code, :contained_code)
  end
end
