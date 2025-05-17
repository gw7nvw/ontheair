# frozen_string_literal: true

# typed: false
class StaticPagesController < ApplicationController
  include ApplicationHelper

  def ack_news
    if current_user
      current_user.hide_news_at = Time.now
      current_user.save
    end
    redirect_to '/'
  end

  def home
    # Hanging this here just because
    time_now = Time.now
    as = AdminSettings.last
    if !as.last_sota_activation_update_at || ((as.last_sota_activation_update_at + 30.days) < time_now)
      if ENV['RAILS_ENV'] == 'production'
        Resque.enqueue(UpdateExternalActivations)
        Resque.enqueue(ExportAssets)
      elsif ENV['RAILS_ENV'] == 'development'
        as.last_sota_activation_update_at = Time.now
        as.save
        ExternalActivation.import_sota
        ExternalActivation.import_pota
      end
    end

    spots
    ack_time = current_user.hide_news_at if current_user
    ack_time ||= '1900-01-01'

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

  def spots
    onehourago = Time.at(Time.now.to_i - 60 * 60 * 1).in_time_zone('UTC').to_s

    @zone = 'OC'
    @zone = params[:zone] if params[:zone]

    # read spots from db
    @all_spots = ExternalSpot.where("time>'" + onehourago + "'")

    @hota_spots = Post.find_by_sql ["
            select p.* from posts p
            inner join items i on i.item_id=p.id and i.item_type='post'
            where
              i.topic_id=#{SPOT_TOPIC} and p.referenced_date>'#{Time.now.to_date - 1.days}'
              and (p.referenced_time>'#{Time.now - 1.hours}' or p.referenced_time is null)
            order by p.created_at desc;
      "]
    @hota_spots.each do |post|
      created_by = User.find_by(id: post.created_by_id)
      created_by_callsign = created_by ? created_by.callsign : ''
      @all_spots.push(ExternalSpot.new(
                        spot_type: 'ZLOTA',
                        time: post.referenced_time ? post.referenced_time.in_time_zone('UTC') : '',
                        activatorCallsign: post.callsign,
                        callsign: created_by_callsign,
                        code: post.asset_codes,
                        frequency: post.freq,
                        mode: post.mode,
                        name: post.site,
                        comments: (post.title || '') + ' - ' + (post.description || ''),
                        id: -post.id
                      ))
    end

    if @all_spots then @all_spots = @all_spots.sort_by { |hsh| hsh[:date].to_s + hsh[:time].to_s }.reverse! end

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

  def alerts
    zlvk_sota_alerts = []
    zlvk_pota_alerts = []

    items = Item.where(topic_id: 1, item_type: 'post').order(:created_at).reverse
    @hota_alerts = []
    items.each do |i|
      p = Post.find(i.item_id)
      if p && p.referenced_date && (p.referenced_date > Time.now - (p.duration || 1).days) then @hota_alerts.push(p) end
    end
    if @hota_alerts && (@hota_alerts.count > 0) then @hota_alerts = @hota_alerts.sort_by { |h| if h.referenced_date then h.referenced_date.strftime('%Y-%m-%d')+' '+if h.referenced_time then h.referenced_time.strftime('%H:%M') else '' end else '' end }.reverse end

    begin
      url = 'http://parksnpeaks.org/api/ALERTS/'
      pnp_alerts = JSON.parse(open(url).read)
    rescue StandardError
      flash[:error] = "Received invalid alert data from Parks'n'Peaks. Showing only local alerts"
      pnp_alerts = []
    end

    @all_alerts = []
    zlvk_sota_alerts.each do |alert|
      @all_alerts.push(
           starttime: if alert["dateActivated"].to_datetime then alert["dateActivated"].to_datetime.in_time_zone(@tz.name).strftime("%Y-%m-%d %H:%M") else "" end,
           activatingCallsign: alert['activatingCallsign'].strip,
           code: alert['associationCode'] + '/' + alert['summitCode'],
           name: alert['summitDetails'],
           frequency: alert['frequency'],
           mode: alert['mode'],
           comments: alert['comments'],
           type: 'SOTA'
         )
    end

    zlvk_pota_alerts.each do |alert|
      @all_alerts.push(
          starttime: if alert['Start Date'].to_datetime then alert['Start Date'].to_datetime.in_time_zone(@tz.name).strftime('%Y-%m-%d %H:%M') + (if alert['End Date'].to_datetime then ' to ' + alert['End Date'].to_datetime.in_time_zone(@tz.name).strftime('%Y-%m-%d %H:%M') else '' end) else '' end,
          activatingCallsign: alert['Activator'].strip,
          code: alert['Reference'],
          name: alert['Park Name'],
          frequency: alert['Frequecies'],
          mode: '',
          comments: alert['Comments'],
          type: 'POTA'
        )
    end

    pnp_alerts.each do |alert|
      @all_alerts.push(
           starttime: if alert['alTime'].to_datetime then alert['alTime'].to_datetime.in_time_zone(@tz.name).strftime('%Y-%m-%d %H:%M') + ( if alert['alDay'] == '1' then ' (Day)' elsif alert['alDay'] == '2' then ' (Morning)' elsif alert['alDay'] == '3' then ' (Afternoon)' elsif alert['alDay'] == '4' then ' (Evening)' elsif alert['alDay'] == '5' then ' (Overnight)' else '' end) else '' end,
           activatingCallsign: alert['CallSign'].strip,
           code: alert['WWFFID'] && !alert['WWFFID'].empty? ? alert['WWFFID'] : alert['Location'],
           name: alert['Location'],
           frequency: alert['Freq'],
           mode: alert['MODE'],
           comments: alert['Comments'],
           type: 'PnP: ' + alert['Class']
         )
    end

    @all_alerts.sort_by! { |hsh| hsh[:starttime] }.reverse! if @all_alerts
  end
end
