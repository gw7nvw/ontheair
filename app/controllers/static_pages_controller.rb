# frozen_string_literal: true

# typed: false
class StaticPagesController < ApplicationController
  include ApplicationHelper

  before_action :signed_in_user, only: %i[ack_news admin_stats  recent results]

  def ack_news
    if current_user
      current_user.hide_news_at = Time.now
      current_user.save
    end
    redirect_to '/'
  end

  def admin_stats
    if current_user.is_web_admin then
      @memstats=`top -b -o %MEM -n 1 | head -n 5`
      @diskstats = `df -k`
      @resque_workers = `ps -ef | grep Waiting | grep -v grep`
      @as = AdminSettings.last
    else
      flash[:error]="You do not have permission to view this page"
      redirect_to '/'
    end
  end

  def dxcc
    session[:dxcc]=params[:id].upcase
    if current_user
      current_user.dxcc=params[:id].upcase
      current_user.save
    end
    @site_title_unquoted = "... On The Air"
    @site_title_unquoted = "ZL "+@site_title_unquoted if session[:dxcc]=='ZL'
    @site_title_quoted="'"+@site_title_unquoted+"'"
    home
    render "home"
  end

  def home
    spots
    ack_time = current_user.hide_news_at if current_user
    ack_time ||= '1900-01-01'
    @dxcc = session[:dxcc]
    @dxcc='ZL' if !@dxcc

    @max_rows = 30
    results
    @users = @full_users

    @static_page = true
    @brief = true
    @fulllogs = Log.find_by_sql [" select * from logs where asset_codes != '{}' order by date desc limit 20 "]
    @logs = @fulllogs.paginate(per_page: 20, page: params[:page])

    @awards = AwardUserLink.find_by_sql [ "select * from award_user_links where created_at>'#{ack_time}'; "]
    @award_users = User.find_by_sql [ "select * from users where id in (select distinct user_id from award_user_links where created_at>'#{ack_time}') order by callsign;"]

    @items = Item.find_by_sql ["select * from items where (topic_id = 4 )and item_type = 'post' and created_at>'#{ack_time}' order by created_at desc limit 4;"]
    @asset_type_filter = "('all', 'silo')" if @dxcc=='ZL'
    @asset_type_filter = "('park', 'lake', 'lighthouse', 'island', 'hut', 'volcano', 'all')" if @dxcc=="VK"
  end

  def recent
    @fulllogs = Log.find_by_sql [' select * from logs order by date desc ']
    @logs = @fulllogs.paginate(per_page: 20, page: params[:page])
  end

  def results
    @max_rows ||= 2000

    @scoreby = params[:scoreby]
    @scoreby = 'bagged' if !@scoreby || (@scoreby == '')

    @static_page = true
    @sortby = params[:sortby]
    if !@sortby || (@sortby == '')
      cats = AssetType.where('keep_score = true')
      @sortby = cats[rand(0..cats.count - 1)].name
    end
    if @scoreby == 'qualified'
      scorefield = 'qualified_count_total'
    elsif @scoreby == 'activated'
      scorefield = 'activated_count_total'
    elsif @scoreby == 'chased'
      scorefield = 'chased_count_total'
    else
      scorefield = 'score'
      @scoreby = 'bagged'
    end

    @full_users = User.users_with_assets(@sortby, scorefield, @max_rows)
    @users = @full_users.paginate(per_page: 40, page: params[:page])
  end

  def help
    @items = Item.where(topic_id: HELP_TOPIC).order(:created_at).reverse
  end

  def faq
    @items = Item.where(topic_id: FAQ_TOPIC).order(:created_at).reverse
  end

  def spot_history
    @start_date = params[:start_date] if params[:start_date]
    @end_date = params[:end_date] if params[:end_date]
    @this_dxcc = params[:dxcc][:prefix] if params[:dxcc]
    puts "DXCC:#{@this_dxcc.to_s}:"
    @activator = params[:activator] if params[:activator] 
    @reference = params[:reference] if params[:reference]
    @programme = params[:programme][:name] if params[:programme]

    blank_search = true if !@start_date 
    #defaults
    @start_date = 24.hours.ago.to_date if !@start_date
    @end_date = Time.now.to_date if !@end_date
    @this_dxcc=session[:dxcc] if !@this_dxcc
    puts "DXCC:#{@this_dxcc.to_s}:"
    @dxcc="All" if !@this_dxcc
    puts "DXCC:#{@this_dxcc.to_s}:"
    @activator="*" if !@activator or @activator.strip==""
    @reference="*" if !@reference or @reference.strip==""
    @programme="All" if !@programme
    spots=[] 
    iso_code=''
    if @this_dxcc == 'VK' then
      iso_code = 'AU'
    elsif @this_dxcc == 'ZL'
      iso_code = 'NZ'
    end
    spots = ConsolidatedSpot.where(%Q{date_trunc('day',created_at)>='#{@start_date}' and date_trunc('day',updated_at) <='#{@end_date}' and ('#{@programme}' = ANY(spot_type) or '#{@programme}' = 'All') and (ARRAY_TO_STRING(code,' ') like '%#{@this_dxcc.gsub('All','')}%' or ARRAY_TO_STRING(code, ' ') like '%#{iso_code}%') and "activatorCallsign" like '#{@activator.gsub("*","%")}' and ('#{@reference}'=ANY(code)  or '#{@reference}'='*')}) if !blank_search
    @spot_count = spots.count
    @all_spots = spots[0..199]
  end

  def spots
    alerts

    hoursago = 1
    hoursago = params[:hoursago].to_i if params[:hoursago]

    onehourago = Time.at(Time.now.to_i - 60 * 60 * hoursago).in_time_zone('UTC').to_s

    @zone = 'OC'
    @zone = params[:zone] if params[:zone]

    # read spots from db
    @all_spots = ConsolidatedSpot.where("updated_at>'" + onehourago + "'")

    if @all_spots then @all_spots = @all_spots.sort_by { |hsh| hsh[:date].to_s + hsh[:time].last.to_s }.reverse! end

    if @zone && (@zone != 'all')
      @all_spots = @all_spots.select { |spot| DxccPrefix.continent_from_call(spot[:activatorCallsign]) == @zone }
    end

    if params[:class]
      @class = params[:class]
      @all_spots = @all_spots.select { |spot| spot[:spot_type].include? @class }
    end

    if params[:mode]
      @mode = params[:mode]
      @all_spots = @all_spots.select { |spot| @mode.upcase.include? spot[:mode].upcase }
    end
  end

  def delete_alert
    alert = ExternalAlert.find_by(id: params[:id])
    if current_user and (current_user.is_admin or current_user.is_web_admin or current_user.callsign == alert.activatingCallsign) then
      alert.destroy
      flash[:success] = "Alert #{params[:id]} deleted"
    else
      flash[:error] = "You do not have permissions to delete this alert"
    end
    alerts()
    redirect_to '/alerts'
  end

  def alerts
    @zone = 'OC'
    @zone = params[:zone] if params[:zone]

    hota_alerts = Post.find_by_sql [ " select p.*, i.id as item_id from posts p inner join items i on i.item_id=p.id and i.topic_id=1 and i.item_type='post' and ((p.referenced_date + interval '1 hours' * duration::numeric) > '#{(Time.now - 1.days).strftime("%Y-%m-%d %H:%M")}' or p.referenced_date > '#{(Time.now - 1.days).strftime("%Y-%m-%d %H:%M")}')" ]

    @all_alerts = ExternalAlert.find_by_sql [ " select * from external_alerts where starttime >'#{Time.now - 1.days}' or (starttime + interval '1 hours' * duration::numeric) >'#{Time.now - 1.days}' order by starttime desc " ] 
    @all_alerts += ExternalAlert.import_hota_alerts(hota_alerts)

    if @all_alerts then @all_alerts = @all_alerts.sort_by { |hsh| hsh[:starttime].to_s }.reverse! end

    if @zone && (@zone != 'all')
      @all_alerts = @all_alerts.select { |alert| DxccPrefix.continent_from_call(alert[:activatingCallsign]) == @zone }
    end

    if params[:class]
      @class = params[:class]
      @all_alerts = @all_alerts.select { |alert| alert[:programme].include? @class }
    end
  end
end
