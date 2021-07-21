class ImagesController < ApplicationController

before_action :signed_in_user, only: [:delete, :create, :update]

def delete
 if signed_in?  then
    @image=Image.find_by_id(params[:id])
    if @image and (current_user.is_admin or (current_user.id==@image.created_by_id)) then
      if @image.destroy
        flash[:success] = "Image deleted, id:"+params[:id]
        redirect_to '/'
      else
        flash[:error] = "Failed to delete image"
        redirect_to '/'
      end
    else
      flash[:error] = "Failed to delete image"
      redirect_to '/'
    end
  else
    flash[:error] = "Failed to delete image"
    redirect_to '/'
  end
end

end
