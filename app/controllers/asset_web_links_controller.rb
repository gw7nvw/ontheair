# typed: false
class AssetWebLinksController < ApplicationController
before_action :signed_in_user

def create
  if signed_in?  then
    if Asset.find_by(code: params[:asset_web_link][:asset_code].gsub('_','/')) then
      if awl=AssetWebLink.create(asset_web_link_params) then
        awl.asset_code=awl.asset_code.gsub('_','/')
        if awl.url[0..3]!='http' then awl.url='http://'+awl.url end
        awl.save
        flash[:success]="Link created"
      else
        flash[:error]="Could not create link"
      end
      asset_code=awl.asset_code 
      if asset_code then
        redirect_to '/assets/'+asset_code.gsub('/','_')
      else
        redirect_to '/'
      end
    else
      flash[:error]="Asset not found"
      redirect_to '/'
    end
  else
    flash[:error]="You must be logged in to create links"
    redirect_to '/'
  end
end


def delete
  if signed_in?  then
    awl=AssetWebLink.find_by(id: params[:id])
    if awl and awl.destroy then
      flash[:success]="Link deleted"
    else
      flash[:error]="Failed to delete link"
    end
    if awl and awl.asset_code then
      redirect_to '/assets/'+awl.asset_code.gsub('/','_')
    else
      redirect_to '/'
    end
  else 
    flash[:error]="You must be logged in to delete this link"
    redirect_to '/'
  end
end

  private
  def asset_web_link_params
    params.require(:asset_web_link).permit(:id, :link_class, :asset_code, :url)
  end

end
