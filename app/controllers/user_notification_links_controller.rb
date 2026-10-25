# typed: false
    
class UserNotificationLinksController < ApplicationController
  include ApplicationHelper
  include UserViewPreparer
  before_action :signed_in_user

  def edit
    if params[:id] then
      @filter = UserNotificationLink.find_by(id: params[:id])
      prepare_user_show_data(@filter.user_id)
    end
    if !@user then
      flash[:error] = "Invalid user or notification record"
      redirect_to '/'
    else
      render "users/show"
    end
  end

  def update
    user_id = params[:user_notification_link][:user_id]
    if user_id!=current_user.id and current_user.is_admin==false
      flash[:error]="You do not have permission to edit this record"
    else
      @filter = UserNotificationLink.find_by(id: params[:id])
      @filter.assign_attributes(user_notification_link_params) if @filter
      if @filter.save
        flash[:success]="Saved notification filter"
        @filter=UserNotificationLink.new
        @filter.priority=0
        @filter.user_id=user_id
      else
        flash[:error]=@filter.errors
      end
    end
    prepare_user_show_data(user_id)
    render "users/show"
  end

  def create
    user_id = params[:user_notification_link][:user_id]
    if user_id!=current_user.id and current_user.is_admin==false
      flash[:error]="You do not have permission to edit this record"
    else
      @filter = UserNotificationLink.new(user_notification_link_params)
      if @filter.save
        flash[:success]="Saved notification filter"
        @filter=UserNotificationLink.new
        @filter.priority=0
        @filter.user_id=user_id
      else
        flash[:error]=@filter.errors
      end
    end
    prepare_user_show_data(user_id)
    render "users/show"
  end

  def delete
    user_id = params[:user_id]
    if user_id!=current_user.id and current_user.is_admin==false
      flash[:error]="You do not have permission to edit this record"
    else
      @filter = UserNotificationLink.find_by(id: params[:id])
      @filter.destroy
      @filter=UserNotificationLink.new
      @filter.priority=0
      @filter.user_id=user_id
    end
    prepare_user_show_data(user_id)
    render "users/show"
  end

  private

  def user_notification_link_params
    params.require(:user_notification_link).permit(:id, :user_id, :activator_callsign, :code, :priority, continents: [], modes: [], bands: [], spot_types: [] )
  end

end

