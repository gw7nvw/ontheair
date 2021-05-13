class QslController < ApplicationController
  layout 'qsl_layout'

def show
  @maxphoto=0
  @contact=Contact.find_by_id(params[:id])
  if params[:photo] then photo=params[:photo].to_i else photo=0 end
  @call1=false
  @call2=false 
  if current_user and current_user.callsign==@contact.callsign1 then @call1=true end
  if current_user and current_user.callsign==@contact.callsign2 then 
     @call2=true
     @contact=@contact.reverse
  end
  if cals=@contact.activator_asset_links then
    cals.each do |cal| 
      if cal.photos and cal.photos.count>0 then 
        @pic_url="/proxy?url="+cal.photos[photo].link_url
        @photo=photo
        @maxphoto=cal.photos.count-1
      end
    end
  end
  if @maxphoto==0 then
      @call1=nil
      @call2=nil
      flash[:error]="Sorry - only contacts made from places for which we have photographs can currently create QSL cards"
  end
 if !@call1 and !@call2 then
     redirect_to '/'
 end
end

end
