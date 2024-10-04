# frozen_string_literal: true

# typed: false
class PasswordResetsController < ApplicationController
  before_action :get_user,   only: %i[edit update]
  before_action :valid_user, only: %i[edit update]
  before_action :check_expiration, only: %i[edit update]

  def new; end

  def create
    @user = User.find_by(email: params[:password_reset][:email].downcase)
    if @user
      @user.create_reset_digest
      @user.send_password_reset_email
      flash[:info] = 'Email sent with password reset instructions'
      redirect_to root_url
    else
      flash.now[:error] = 'Email address not found'
      render 'new'
    end
  end

  def edit; end

  def update
    if both_passwords_blank?
      flash.now[:error] = "Password/confirmation can't be blank"
      render 'edit'
    elsif @user.update_attributes(user_params)
      # activate too as we use this as fallback activation link
      @user.activate
      sign_in @user
      flash[:success] = 'Password has been reset.'
      redirect_to '/users/' + URI.escape(@user.callsign)
    else
      render 'edit'
    end
  end

  private

  # Returns true if password & confirmation are blank.
  def both_passwords_blank?
    params[:user][:password].blank? &&
      params[:user][:password_confirmation].blank?
  end

  def get_user
    @user = User.find_by(email: params[:email])
    end

  # Confirms a valid user.
  def valid_user
    unless @user && @user.authenticated?(:reset, params[:id])
      redirect_to root_url
    end
  end

  # Checks expiration of reset token.
  def check_expiration
    if @user.password_reset_expired?
      flash[:error] = 'Password reset has expired.'
      redirect_to new_password_reset_url
    end
  end

  def user_params
    params.require(:user).permit(:password, :password_confirmation)
  end
end
