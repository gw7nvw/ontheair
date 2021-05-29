class AssetLinksController < ApplicationController
before_action :signed_in_user

def create
  if signed_in?  then
   if ca=Asset.find_by(code: params[:asset_link][:child_code].gsub('_','/')) and 
      cp=Asset.find_by(code: params[:asset_link][:parent_code].gsub('_','/')) then
     if awl=AssetLink.create(child_code: ca.code, parent_code: cp.code) then
       awl.save
       flash[:success]="Link created"
     else
       flash[:error]="Could not create link"
     end
     asset_code=params[:asset_code]
     redirect_to '/assets/'+asset_code.gsub('/','_')+"/associations"
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
   awl=AssetLink.find_by(id: params[:id])
   asset_code=params[:asset_code]
   if  awl.destroy then
     flash[:success]="Link deleted"
     redirect_to '/assets/'+asset_code.gsub('/','_')+"/associations"
   else
     flash[:error]="Failed to delete link"
     redirect_to '/assets/'+asset_code.gsub('/','_')+"/associations"
   end
 else 
   flash[:error]="You must be logged in to delete this link"
   redirect_to '/'
 end
end
  private
  def asset_web_link_params
    params.require(:asset_web_link).permit(:child_code, :parent_code)
  end

end
