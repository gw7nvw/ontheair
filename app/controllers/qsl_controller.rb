# frozen_string_literal: true

# typed: false
class QslController < ApplicationController
  layout 'qsl_layout'

  def show
    @maxphoto = 0
    @contact = Contact.find_by_id(params[:id])
    photo = params[:photo] ? params[:photo].to_i : 0
    @call1 = false
    @call2 = false
    @call1 = true if current_user && (current_user.id == @contact.user1_id)
    if current_user && (current_user.id == @contact.user2_id)
      @call2 = true
      @contact = @contact.reverse
    end
    if cals = @contact.activator_assets
      cals.each do |cal|
        next unless cal.photos && (cal.photos.count > 0)
        @pic_url = if cal.photos[photo].link_url[0..3] == 'http'
                     '/proxy?url=' + cal.photos[photo].link_url
                   else
                     cal.photos[photo].link_url
                   end
        @photo = photo
        @maxphoto = cal.photos.count
      end
    end
    if @maxphoto == 0
      @call1 = nil
      @call2 = nil
      flash[:error] = 'Sorry - only contacts made from places for which we have photographs can currently create QSL cards'
    end
    redirect_to '/' if !@call1 && !@call2
  end
end
