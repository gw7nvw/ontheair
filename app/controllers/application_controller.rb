# frozen_string_literal: true

# typed: false
class ApplicationController < ActionController::Base
  before_action :determine_country
  helper_method :current_country 
  helper_method :safe_session_get

  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  before_filter :set_cache_headers
  before_filter :log_visit
  before_action :store_last_index_page
#  before_action :trigger_scheduled_jobs
  before_action :global_variables
  #  before_action :check_resque_workers

  include SessionsHelper
  include MapHelper
  include RgeoHelper

  helper_method :retrieve_last_index_page_or_default

  def global_variables
    as=AdminSettings.first
    @default_layer = params[:baselayer] if params[:baselayer]
    if current_user then
      @default_layer = current_user.baselayer if current_user.baselayer and !@default_layer
      @default_layer = as.default_layer if !@default_layer
    end
    @preferred_layer = @default_layer

    if @current_country=='VK'
      @dxcc = 'VK'
      @default_x =  16085209
      @default_y = -4006631
      @zoomlevel = 6
    else
      @dxcc = 'ZL'
      @default_x =  19430000
      @default_y = -5040000
      @zoomlevel = 7
    end

 
    if @current_country=='VK' then as.title = as.title.gsub('ZL','VK') end
    @site_title="'"+as.title+"'"
    @site_title_unquoted=as.title
    @site_title_image=as.imagepath
    @site_name=as.name

    # parameters
    @parameters = params_to_query

    # referring page
    @referring = params[:referring] if params[:referring]

    # timezones
    if current_user
      tzid = current_user.timezone
      @tz = Timezone.find(tzid)
    else
      @tz = Timezone.find_by(name: 'UTC')
    end
    #@map_x=as.default_x.to_d
    #@map_y=as.default_y.to_d
    x = params[:x] if params[:x]
    y = params[:y] if params[:y]
    if x and y then
      if params[:epsg] then 
        srs=params[:epsg].to_i 
      else
        srs=4326
      end
  
      trs=2193
      xyarr= transform_geom(x, y, srs, trs)
      @map_x=xyarr[0]
      @map_y=xyarr[1]
    end
    @zoomlevel = params[:zoom] if params[:zoom]
    @proj=as.default_projection    
    @preferred_layer=as.default_layer  if !@preferred_layer
    m = Maplayer.find_by(name: @preferred_layer)
    @preferred_extent=m.extent if m
    @proj = 'EPSG:'+params[:proj] if params[:proj]
    #session[:proj] = @proj if has_session_cookie?
    @proj_srs=@proj[5..-1].to_i
    @layer = params[:layer] if params[:layer]
    @default_pointlayers = current_user.pointlayers if current_user
    @default_polygonlayers = current_user.polygonlayers if current_user
  end

  def trigger_scheduled_jobs
    time_now = Time.now
    as = AdminSettings.last
    if !as.last_monthly_sched_at || ((as.last_monthly_sched_at + 30.days) < time_now)
      if ENV['RAILS_ENV'] == 'production'
        Resque.enqueue(ExportAssets)
        Resque.enqueue(TidyUserAgentsJob)
        as.update_attribute(:last_monthly_sched_at, Time.now)
      elsif ENV['RAILS_ENV'] == 'development'
        as.update_attribute(:last_monthly_sched_at, Time.now)
      end
    end

    if !as.last_minute_sched_at || ((as.last_minute_sched_at + 1.minute) < time_now)
      if ENV['RAILS_ENV'] == 'production'
        Resque.enqueue(UpdateExternalActivations)
      elsif ENV['RAILS_ENV'] == 'development'
        ExternalActivation.import_next_sota
        ExternalActivation.import_next_pota
        as.update_attribute(:last_minute_sched_at, Time.now)
      end
    end
 
  end

  def store_last_index_page
    if request.referrer.present?
      begin
        uri = URI.parse(request.referer)
        if uri.host.nil? || uri.host == request.host
          # Combine just the path and the query params (e.g., "/items?page=2&dxcc=AU")
          last_url = "#{uri.path}?#{uri.query}".chomp("?")
          #iitialise the stack if empty
          session[:last_index_page] = [] if session[:last_index_page] == nil 
    
          # pop a page for back
          if params[:back]
            session[:last_index_page].pop
          #or add last page for forward
          else
            unless ['/styles.js', '/query', '/layerswitcher', '/legend'].include?(request.fullpath.split('?').first)
              session[:last_index_page].push("#{uri.path}?#{uri.query}".chomp("?").gsub('?back=true','').gsub('&back=true',''))
            end
          end
        end
      rescue URI::InvalidURIError
    # Fallback to default if the referrer string is corrupted
      end
    end
  end

  def retrieve_last_index_page_or_default(default_path: root_path)
    if has_session_cookie? 
      if session[:last_index_page].present?
        concat_char = (session[:last_index_page][-1] || default_path).include?('?') ? '&' : '?'
        (session[:last_index_page][-1] || default_path) + concat_char + 'back=true'
      end
    end
  end

  def signed_in_user
    redirect_to signin_url + '?referring_url=' + URI.escape(request.fullpath), notice: 'Please sign in.' unless signed_in?
  end

  def log_visit
    if request.env['HTTP_USER_AGENT'] && request.env['HTTP_USER_AGENT'].match(/\(.*https?:\/\/.*\)/)
      Rails.logger.info 'BOT: ' + request.remote_ip
    else
      Rails.logger.info request.env['HTTP_USER_AGENT']
      if signed_in?
        Rails.logger.info 'USER: ' + current_user.callsign + ' - ' + request.remote_ip
      else
        Rails.logger.info 'USER: ' + request.remote_ip
      end
    end
    if current_user then 
      current_user.update_column :updated_at, Time.now()
    end
  end

  def set_cache_headers
    #response.headers['Cache-Control'] = 'max-age=30, public'
    response.headers['Pragma'] = 'no-cache'
    response.headers['Expires'] = 'Fri, 01 Jan 1990 00:00:00 GMT'
  end

  def collection_to_csv(items)
    require 'csv'
    csvtext = ''
    if items && items.first
      columns = []; items.first.attributes.each_pair { |name, _value| columns << name }
      csvtext << columns.to_csv
      items.each do |item|
        fields = []; item.attributes.each_pair { |_name, value| fields << value }
        csvtext << fields.to_csv
      end
   end
    csvtext
  end

  def params_to_query
    newparams = params.dup
    newparams.delete(:action)
    newparams.delete(:controller)
    newparams.delete(:id)
    newparams.to_query
  end
  
  def do_not_cache
    response.headers['Cache-Control'] = 'no-cache, no-store, must-revalidate' # HTTP 1.1.
    response.headers['Pragma'] = 'no-cache' # HTTP 1.0.
    response.headers['Expires'] = '0' # Proxies.
  end

  def current_country
    @current_country
  end

  private

  # Centralized cookie check to protect our database from bot lookups
  def has_session_cookie?
    (cookies[:remember_token2].present? or cookies[:remember_token3].present?)
  end

  def safe_session_get(key, default_value = nil)
    if has_session_cookie?
      session[key] || default_value
    else
      default_value
    end
  end

  def determine_country
    if params[:dxcc].present? and params[:dxcc].class.to_s=="String"
      # 1. Absolute Highest Priority: The user just explicitly chose a country via an action/link
      @current_country=params[:dxcc].upcase
      session[:dxcc] = @current_country
      # 2. Check if they have an active session cookie
    elsif has_session_cookie? && session[:dxcc].present?
      @current_country = session[:dxcc]
    elsif current_user.present? && current_user.dxcc.present?
      # 3. Second Priority: Use the logged-in user's profile database setting
      @current_country = current_user.dxcc
      session[:dxcc] = @current_country 
    else
      # 4. Fall back to the domain name if no session exists (or if it's an empty session)
      @current_country = case request.host
                         when /.*\.nz$/
                           'ZL'
                         when /.*\.com\.au$/
                           'VK'
                         else
                           'ZL' # Default fallback
                         end
    end
  end
end
