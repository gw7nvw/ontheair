# frozen_string_literal: true

# typed: false
class ImagesController < ApplicationController
  before_action :signed_in_user

#  def delete
#    if signed_in?
#      @image = Image.find_by_id(params[:id])
#      if @image && (current_user.is_admin || (current_user.id == @image.created_by_id))
#        if @image.destroy
#          flash[:success] = 'Image deleted, id:' + params[:id]
#          redirect_to '/'
#        else
#          flash[:error] = 'Failed to delete image'
#          redirect_to '/'
#        end
#      else
#        flash[:error] = 'Failed to delete image'
#        redirect_to '/'
#      end
#    else
#      flash[:error] = 'Failed to delete image'
#      redirect_to '/'
#     end
#  end
end
