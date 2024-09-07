class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  before_filter :set_cache_headers
  before_filter :log_visit
  before_action :store_last_index_page
#  before_action :check_resque_workers


  include SessionsHelper
  include RgeoHelper

  helper_method :retrieve_last_index_page_or_default

  def store_last_index_page
    if session[:last_index_page]==nil then 
      session[:last_index_page]=[] 
    end


    if params[:back] then 
      session[:last_index_page].pop
    else
      if not ["/styles.js","/query","/layerswitcher","/legend"].include?(request.fullpath.split("?").first) then 
        session[:last_index_page].push(request.fullpath).split("?back=true").first.split("&back=true").first
      end
    end
  end

  def retrieve_last_index_page_or_default(default_path: root_path)
    if (session[:last_index_page][-2] || default_path).include?("?") then concat_char="&" else concat_char="?" end

    (session[:last_index_page][-2] || default_path)+concat_char+"back=true"
  end

  def signed_in_user
      redirect_to signin_url+"?referring_url="+URI.escape(request.fullpath), notice: "Please sign in." unless signed_in?
  end

  def log_visit
   if request.env["HTTP_USER_AGENT"] and request.env["HTTP_USER_AGENT"].match(/\(.*https?:\/\/.*\)/) then
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
