# frozen_string_literal: false

# typed: false
class ApiController < ApplicationController
  include PostsHelper

  require 'rexml/document'

  skip_before_filter :verify_authenticity_token

  def index; end

  def assettype
    respond_to do |format|
      format.js { render json: AssetType.all.to_json }
      format.html { render json: AssetType.all.to_json }
      format.csv { send_data asset_to_csv(AssetType.all), filename: "assettypes-#{Date.today}.csv" }
    end
  end

  def assetlink
    if params[:id]
      id = params[:id].upcase.tr('_', '/')
      if params[:contained_by_assets]
        respond_to do |format|
          format.js { render json: AssetLink.where(containing_code: id).to_json }
          format.html { render json: AssetLink.where(containing_code: id).to_json }
          format.csv { send_data asset_to_csv(AssetLink.where(containing_code: id)), filename: "assetlinks-#{Date.today}.csv" }
        end
      else
        respond_to do |format|
          format.js { render json: AssetLink.where(contained_code: id).to_json }
          format.html { render json: AssetLink.where(contained_code: id).to_json }
          format.csv { send_data asset_to_csv(AssetLink.where(contained_code: id)), filename: "assetlinks-#{Date.today}.csv" }
        end
      end

    elsif params[:asset_type] && params[:contained_by_assets]
      assetLinks = AssetLink.find_by_sql [" select al.* from asset_links al inner join assets a on a.code = al.containing_code where a.asset_type='#{params[:asset_type]}'; "]
      respond_to do |format|
        format.js { render json: assetLinks.to_json }
        format.html { render json: assetLinks.to_json }
        format.csv { send_data asset_to_csv(assetLinks), filename: "assetlinks-#{Date.today}.csv" }
      end

    elsif params[:asset_type]
      assetLinks = AssetLink.find_by_sql [" select al.* from asset_links al inner join assets a on a.code = al.contained_code where a.asset_type='#{params[:asset_type]}'; "]
      respond_to do |format|
        format.js { render json: assetLinks.to_json }
        format.html { render json: assetLinks.to_json }
        format.csv { send_data asset_to_csv(assetLinks), filename: "assetlinks-#{Date.today}.csv" }
      end

    else
      respond_to do |format|
        format.js { render json: AssetLink.all.to_json }
        format.html { render json: AssetLink.all.to_json }
        format.csv { send_data asset_to_csv(AssetLink.all), filename: "assetlinks-#{Date.today}.csv" }
      end
    end
  end

  def asset
    whereclause = 'true'
    base_filename = 'assets'

    whereclause = 'is_active is true' unless params[:is_active]

    whereclause += ' and minor is not true' unless params[:minor]

    if params[:asset_type] && (params[:asset_type] != '') && (params[:asset_type] != 'all')
      asset_type = params[:asset_type]
      base_filename = params[:asset_type].strip
    end

    if params[:updated_since]
      whereclause += " and updated_at > '" + params[:updated_since] + "'"
    end

    if asset_type then 
      whereclause += " and asset_type = '" + asset_type + "'" 
    else
      ats=AssetType.where(is_zlota: true)
      whereclause += " and asset_type in ("+ats.map{|at| "'"+at.name+"'"}.join(', ')+")"
    end

    @searchtext = params[:searchtext] || ''
    if params[:searchtext]
      whereclause = whereclause + " and (lower(name) like '%%" + @searchtext.downcase + "%%' or lower(code) like '%%" + @searchtext.downcase + "%%')"
    end

    @assets = Asset.find_by_sql ['select id, url, asset_type, code, name,location,altitude,minor,is_active,region,created_at, updated_at,old_code,area from assets where ' + whereclause]

    respond_to do |format|
      format.js { render json: @assets.to_json }
      format.html { render json: @assets.to_json }
      format.csv { send_data asset_to_csv(@assets), filename: "#{base_filename}-#{Date.today}.csv" }
      format.gpx { send_data asset_to_gpx(@assets), filename: "#{base_filename}-#{Date.today}.gpx" }
    end
  end

  def spot
    start_time = 2.hours.ago
    if params[:start_time] then 
      start_time=params[:start_time].to_time
    end
    
    spots=Post.find_by_sql [ "select p.id, p.description as comments, p.referenced_time, rtrim(p.site,'; ') as name, UNNEST(p.asset_codes) as reference, CAST(substring(coalesce(freq, '0') from '[0-9.]+') AS NUMERIC)*1000 as frequency, p.mode, p.callsign as activator, u.callsign as spotter from posts p inner join items i on i.item_type='post' and i.item_id=p.id inner join users u on u.id = p.updated_by_id where i.topic_id=#{SPOT_TOPIC} and p.updated_at>'#{start_time.strftime("%Y-%m-%d %H:%M:%S")}'limit 200;" ]

    if params[:zlota_only] then
     orig_spots=spots
     spots=[]
     orig_spots.each do |spot|
       a=Asset.find_by(code: spot[:reference])
       if a and a.type.is_zlota then
         spots+=[spot]
       end
     end
  
    end
    respond_to do |format|
      format.js { render json: spots.to_json }
      format.json { render json: spots.to_json }
      format.html { render json: spots.to_json }
      format.csv { send_data asset_to_csv(spots), filename: "spots-#{Time.now.strftime("%Y-%m-%dT%H:%M:%SZ")}.csv" }
    end
  end

  def spot_post
    if api_authenticate(params)
      user = User.find_by(callsign: params[:userID].upcase)
      res = { success: true, message: 'Thanks for the data!' }
      p = Post.new
      p.callsign = params[:activator] || ''
      p.freq = params[:frequency].to_f/1000
      p.mode = params[:mode] || ''
      p.created_by_id = user.id
      p.updated_by_id = user.id
      p.description = params[:comments] || ''
      if !user then 
        user = User.find_by(callsign: 'GUEST') 
        p.description = p.description + ' (via '+params[:spotter]+')'
      end
      asset_code = params[:reference] || ''
      assets = Asset.assets_from_code(asset_code)
      if !assets || assets.count.zero? || assets.first[:code].nil?
        puts 'Asset not known:' + asset_code + ' ... trying to continue'
        a_code = ''
        a_name = 'Unrecognised location: ' + asset_code
        a_ext = false
      else
        a_code = assets.first[:code]
        a_codes = assets.map{|a| a[:code]}
        a_name = assets.first[:name]
        a_ext = assets.first[:external]
      end

      if params[:do_not_lookup] then p.do_not_lookup=true end
      p.asset_codes=a_code != '' ? a_codes : []
      debug = p.description.upcase['DEBUG'] ? true : false
      al_date = Time.now.in_time_zone('UTC').strftime('%Y-%m-%d')
      al_time = Time.now.in_time_zone('UTC').strftime('%H:%M')
      p.referenced_time = (al_date + ' ' + al_time + ' UTC').to_time
      p.referenced_date = (al_date + ' 00:00:00 UTC').to_time
      p.updated_at = Time.now
      p.title = 'SPOT: ' + p.callsign + ' spotted portable at ' + a_name + '[' + a_code + '] on ' + p.freq.to_s + '/' + p.mode + ' at ' + Time.now.in_time_zone('Pacific/Auckland').strftime('%Y-%m-%d %H:%M') + 'NZ'
      topic_id = if debug
                       TEST_SPOT_TOPIC
                     else
                       SPOT_TOPIC
                     end
      success = p.save
      if success
        if a_ext == false
          p.add_map_image
          success = p.save
        end

        item = Item.new
        item.topic_id = topic_id
        item.item_type = 'post'
        item.item_id = p.id
        item.save
        item.send_emails
      else
        puts "Bad spot"
        res = { success: false, message: u.errors.first.to_s }
      end
    else
      puts "Authentication failed"
      res = { success: false, message: 'Authentication failed!' }
    end
    respond_to do |format|
      format.js { render json: res.to_json }
      format.json { render json: res.to_json }
      format.html { render json: res.to_json }
    end
  end

  def logs_post
    if api_authenticate(params)
      user = User.find_by(callsign: params[:userID].upcase)
      res = { success: true, message: 'Thanks for the data!' }
      @upload = Upload.new
      @upload.doc = params[:file]
      res = @upload.save
      puts res
      logfile = File.read(@upload.doc.path)
      logs = Log.import(logfile, nil)
      @upload.destroy
      if logs[:success] == false
        res = { success: false, message: logs[:errors].join(', ') }
      end
      if (logs[:success] == true) && logs[:errors] && (logs[:errors].count > 0)
        res = { success: true, message: 'Warnings: ' + logs[:errors].join(', ') }
      end
    else
      res = { success: false, message: 'Login failed using supplied credentials' }
  end

    respond_to do |format|
      format.js { render json: res.to_json }
      format.html { render json: res.to_json }
    end
  end

  private

  def upload_params
    params.require(:item).permit(:file)
  end

  def api_authenticate(params)
    valid = false
    if params[:userID] && params[:APIKey]
      user = User.find_by(callsign: params[:userID].upcase)
      if user && user.pin.casecmp(params[:APIKey]).zero?
        valid = true
      else
        # authenticate via PnP
        # if not a local user, or is a local user and have allowed PnP logins
        # if !user or (user and user.allow_pnp_login==true) then
        if user && (user.allow_pnp_login == true)
          params = { 'actClass' => 'WWFF', 'actCallsign' => 'test', 'actSite' => 'test', 'mode' => 'SSB', 'freq' => '7.095', 'comments' => 'Test', 'userID' => params[:userID], 'APIKey' => params[:APIKey] }
          res = send_spot_to_pnp(params, '/DEBUG')
          if res.body.match('Success')
            valid = true
            puts 'AUTH: SUCCESS authenticated via PnP'
          else
            puts 'AUTH: FAILED authentication via PnP'
          end
        end
      end
    end
    valid
  end
end
