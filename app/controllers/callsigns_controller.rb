# frozen_string_literal: true

# typed: false
class CallsignsController < ApplicationController
  before_action :signed_in_user

  def edit
    @callsign = UserCallsign.find(params[:id])
    unless signed_in? && ((current_user.id == @callsign.user_id) || current_user.is_admin)
      flash[:error] = 'You do not have permissions to edit this callsign'
      redirect_to '/users'
    end
  end

  def create
    if signed_in?
      @callsign = UserCallsign.new(callsign_params)
      # only admin can add other user's callsigns
      @callsign.user_id = current_user.id unless current_user.is_admin

      if @callsign.save
        flash[:success]="Callsign added"
        if Rails.env.production?
          Resque.enqueue(UpdateUserids, @callsign.callsign)
        else
          User.reassign_userids_used_by_callsign(@callsign.callsign)
        end
        redirect_to '/users/' + @callsign.user.callsign
      else
        render 'new'
      end
    else
      flash[:error] = 'You do not have permissions to take this action'
      redirect_to '/'
    end
  end

  def delete
    if signed_in?
      @callsign = UserCallsign.find(params[:id])
      oldcallsign = @callsign.callsign
      # only admin can add other user's callsigns
      if current_user.is_admin || (current_user.id == @callsign.user_id)
        usercall = @callsign.user.callsign
        if !@callsign.delete
          flash[:error] = 'Delete failed'
        else
          flash[:success] = 'Deleted callsign!'
          if Rails.env.production?
            Resque.enqueue(UpdateUserids, oldcallsign)
          else
            User.reassign_userids_used_by_callsign(oldcallsign)
          end
        end
        redirect_to '/users/' + usercall
      else
        flash[:error] = 'You do not have permissions to delete this callsign'
        redirect_to '/users'
      end
    else
      flash[:error] = 'You do not have permissions to delete this callsign'
      redirect_to '/users'
    end
  end

  def update
    if signed_in?
      unless (@callsign = UserCallsign.find_by_id(params[:id]))
        flash[:error] = 'Callsign does not exist: ' + params[:id]

        # tried to update a nonexistant asset
        redirect_to '/'
      end

      oldcallsign = @callsign.callsign
      @callsign.assign_attributes(callsign_params)
      if current_user.is_admin || (@callsign.user_id == current_user.id)

        if @callsign.save
          flash[:success] = 'Callsign details updated'
          if Rails.env.production?
            Resque.enqueue(UpdateUserids, oldcallsign)
            Resque.enqueue(UpdateUserids, @callsign.callsign)
          else
            User.reassign_userids_used_by_callsign(oldcallsign)
            User.reassign_userids_used_by_callsign(@callsign.callsign)
          end
          redirect_to '/users/' + @callsign.user.callsign
        else
          render 'edit'
        end
      else
        flash[:error] = 'You do not have permissions to edit this callsign'
        redirect_to '/users'
      end
    else
      flash[:error] = 'You do not have permissions to edit this callsign'
      redirect_to '/users'
    end
  end

  private

  def callsign_params
    params.require(:user_callsign).permit(:user_id, :callsign, :from_date, :to_date)
  end
end
