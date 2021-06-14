class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
before_filter :set_cache_headers
  before_filter :log_visit

  include SessionsHelper
  include RgeoHelper

  def signed_in_user
      redirect_to signin_url+"?referring_url="+URI.escape(request.fullpath), notice: "Please sign in." unless signed_in?
  end

  def log_visit
   if request.env["HTTP_USER_AGENT"].match(/\(.*https?:\/\/.*\)/) then
      Rails.logger.info "BOT: "+request.remote_ip
   else
      Rails.logger.info request.env["HTTP_USER_AGENT"]
      if signed_in? then
        Rails.logger.info "USER: "+current_user.callsign+" - "+request.remote_ip
      else
      Rails.logger.info "USER: "+request.remote_ip
      end
   end
  end
  def set_cache_headers
    response.headers["Cache-Control"] = "no-cache, no-store, max-age=0, must-revalidate"
    response.headers["Pragma"] = "no-cache"
    response.headers["Expires"] = "Fri, 01 Jan 1990 00:00:00 GMT"
  end

  def collection_to_csv(items)
    require 'csv'
    csvtext=""
    if items and items.first then
      columns=[]; items.first.attributes.each_pair do |name, value| columns << name end
      csvtext << columns.to_csv
      items.each do |item|
         fields=[]; item.attributes.each_pair do |name, value| fields << value end
         csvtext << fields.to_csv
      end
   end
   csvtext
  end

def params_to_query
    newparams=params.dup
    newparams.delete(:action)
    newparams.delete(:controller)
    newparams.delete(:id)
    newparams.to_query
end
end
