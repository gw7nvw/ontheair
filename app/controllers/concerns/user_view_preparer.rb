module UserViewPreparer
  extend ActiveSupport::Concern

  private
  def prepare_user_show_data(user_id)
    #if we were passed an integer
    @user = User.find_by(id: user_id)
    @user = User.find_by(callsign: user_id) if !@user
    if !@user 
      users = UserCallsign.where(callsign: user_id)
      if users && (users.count > 0)
        @user = users.first.user
        if @user
          redirect_to "/users/" + @user.callsign
        else
          flash[:error] = "Callsign " + user_id + " not found"
          redirect_to "/"
        end
      else
        flash[:error] = "Callsign " + user_id + " not found"
        redirect_to "/"
      end
    elsif @user
      @callsign = UserCallsign.new
      @callsign.user_id = @user.id
    end
  end
end
