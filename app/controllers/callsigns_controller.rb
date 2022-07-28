class CallsignsController < ApplicationController

def edit
  @callsign=UserCallsign.find(params[:id])
end

def create
  if signed_in? then
    @callsign=UserCallsign.new(callsign_params)
    #only admin can add other user's callsigns
    if !current_user.is_admin then @callsign.user_id=current_user.id end
  
    if @callsign.save then
      Resque.enqueue(UpdateUserids, @callsign.callsign)
      redirect_to "/users/"+@callsign.user.callsign
    else
      render 'new'
    end
  else
    flash[:error]="You do not have permissions to take this action"
    redirect_to '/'
  end

end

def delete
  if signed_in? then
    @callsign=UserCallsign.find(params[:id])
    oldcallsign=@callsign.callsign
    #only admin can add other user's callsigns
    if current_user.is_admin or current_user.id=@callsign.user_id then 
      usercall=@callsign.user.callsign
      if !@callsign.delete then
        flash[:error]="Delete failed"
      else
        Resque.enqueue(UpdateUserids, oldcallsign)
      end
      redirect_to "/users/"+usercall 
    else
      flash[:error]="You do not have permissions to take this action"
      redirect_to '/'
    end
  else
    flash[:error]="You do not have permissions to take this action"
    redirect_to '/'
  end
end

def update
  if signed_in? then
    if(!@callsign = UserCallsign.find_by_id(params[:id]))
      flash[:error] = "Callsign does not exist: "+params[:id]

      #tried to update a nonexistant asset
      redirect_to '/'
    end

    oldcallsign=@callsign.callsign
    @callsign.assign_attributes(callsign_params)
    if current_user.is_admin or @callsign.user_id==current_user.id then

      if @callsign.save
        flash[:success] = "Callsign details updated"
        Resque.enqueue(UpdateUserids, @callsign.callsign)
        Resque.enqueue(UpdateUserids, oldcallsign)
        redirect_to '/users/'+@callsign.user.callsign
      else
        render 'edit'
      end
    else
      flash[:error]="You do not have permissions to take this action"
      redirect_to '/'
    end
  else
    flash[:error]="You do not have permissions to take this action"
    redirect_to '/'
  end
end

  private

    def callsign_params
      params.require(:user_callsign).permit(:user_id, :callsign, :from_date, :to_date)
    end

end
