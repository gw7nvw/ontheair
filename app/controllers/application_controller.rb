# frozen_string_literal: true

# typed: false
class ApplicationController < ActionController::Base
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
      session[:dxcc] = current_user.dxcc
      session[:dxcc]='ZL' if session[:dxcc] == nil or session[:dxcc] == ""  
      @default_layer = current_user.baselayer if current_user.baselayer and !@default_layer
      @default_layer = as.default_layer if !@default_layer
    end
    @preferred_layer = @default_layer
    puts "LAYER: #{@default_layer}"
    if params[:dxcc]
      if params[:dxcc][:prefix]
        session[:dxcc]=params[:dxcc][:prefix].upcase
      else
        session[:dxcc]=params[:dxcc].upcase
      end
      params.delete(:dxcc)
    end

    if session[:dxcc]=='VK'
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

 
    if session[:dxcc]=='VK' then as.title = as.title.gsub('ZL','') end
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
    session[:proj] = @proj
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
    session[:last_index_page] = [] if session[:last_index_page].nil?

    if params[:back]
      session[:last_index_page].pop
    else
      unless ['/styles.js', '/query', '/layerswitcher', '/legend'].include?(request.fullpath.split('?').first)
        session[:last_index_page].push(request.fullpath).split('?back=true').first.split('&back=true').first
      end
    end
  end

  def retrieve_last_index_page_or_default(default_path: root_path)
    concat_char = (session[:last_index_page][-2] || default_path).include?('?') ? '&' : '?'

    (session[:last_index_page][-2] || default_path) + concat_char + 'back=true'
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
    response.headers['Cache-Control'] = 'max-age=30, public'
    #response.headers['Pragma'] = 'no-cache'
    #response.headers['Expires'] = 'Fri, 01 Jan 1990 00:00:00 GMT'
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
end
