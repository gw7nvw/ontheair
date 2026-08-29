# frozen_string_literal: true

# typed: false
class SessionsController < ApplicationController
  include SessionsHelper

  def new
    #    key = OpenSSL::PKey::RSA.new(1024)
    #    @public_modulus  = key.public_key.n.to_s(16)
    #    @public_exponent = key.public_key.e.to_s(16)
    #    session[:key] = key.to_pem
  end

  def create
    password = params[:session][:password]

    user = User.find_by(email: params[:session][:email].downcase)
    user ||= User.find_by(callsign: params[:session][:email].strip.upcase)

    if user && user.authenticate(password)
      if user.activated?
        sign_in user
        referring_url = params[:referring_url] || '/'
        if params[:signin_x] && params[:signin_y] && params[:signin_zoom]
          redirect_to referring_url + '?x=' + params[:signin_x] + '&y=' + params[:signin_y] + '&zoom=' + params[:signin_zoom]
        else
          redirect_to referring_url
        end
      else
        message = 'Account not registered. '
        message += 'Please use the sign up link to register this callsign.'
        message += 'Alternatively email mattbriggs@yahoo.com to request manual activation'

        flash[:error] = message
        render 'new'
        end
      # Sign the user in and redirect to the user's show page.
    else
      flash.now[:error] = 'Invalid user/password combination'
      new
      render 'new'
    end
  end

  def destroy
    sign_out
    redirect_to root_url
  end
end
