# frozen_string_literal: false

# typed: false
class ApiController < ApplicationController
  include PostsHelper

  require 'rexml/document'
  require 'asset_import_tools'

  skip_before_filter :verify_authenticity_token

  def index; end

  def assettype
    respond_to do |format|
      format.js { render json: AssetType.all.to_json }
      format.json { render json: AssetType.all.to_json }
      format.html { render json: AssetType.all.to_json }
      format.csv { send_data asset_to_csv(AssetType.all), filename: "assettypes-#{Date.today}.csv" }
    end
  end

  def assetlink

    if params[:equivalents_only] then
      al=AssetLink.find_by_sql [ " select al.id, al.contained_code, al.containing_code, 1 as overlap from asset_links al inner join asset_links al2 on al.contained_code = al2.containing_code and al.containing_code = al2.contained_code inner join assets a1 on a1.code = al.contained_code inner join assets a2 on a2.code = al.containing_code where a1.is_active = true and a2.is_active = true"]

      respond_to do |format|
        format.js { render json: al.to_json }
        format.json { render json: al.to_json }
        format.html { render json: al.to_json }
        format.csv { send_data asset_to_csv(al), filename: "assetlinks-#{Date.today}.csv" }
      end
    elsif params[:id]
      id = params[:id].upcase.tr('_', '/')
      if params[:contained_by_assets]
        respond_to do |format|
          format.js { render json: AssetLink.where(containing_code: id).to_json }
          format.json { render json: AssetLink.where(containing_code: id).to_json }
          format.html { render json: AssetLink.where(containing_code: id).to_json }
          format.csv { send_data asset_to_csv(AssetLink.where(containing_code: id)), filename: "assetlinks-#{Date.today}.csv" }
        end
      else
        respond_to do |format|
          format.js { render json: AssetLink.where(contained_code: id).to_json }
          format.json { render json: AssetLink.where(contained_code: id).to_json }
          format.html { render json: AssetLink.where(contained_code: id).to_json }
          format.csv { send_data asset_to_csv(AssetLink.where(contained_code: id)), filename: "assetlinks-#{Date.today}.csv" }
        end
      end

    elsif params[:asset_type] && params[:contained_by_assets]
      assetLinks = AssetLink.find_by_sql [" select al.* from asset_links al inner join assets a on a.code = al.containing_code where a.asset_type='#{params[:asset_type]}'; "]
      respond_to do |format|
        format.js { render json: assetLinks.to_json }
        format.json { render json: assetLinks.to_json }
        format.html { render json: assetLinks.to_json }
        format.csv { send_data asset_to_csv(assetLinks), filename: "assetlinks-#{Date.today}.csv" }
      end

    elsif params[:asset_type]
      assetLinks = AssetLink.find_by_sql [" select al.* from asset_links al inner join assets a on a.code = al.contained_code where a.asset_type='#{params[:asset_type]}'; "]
      respond_to do |format|
        format.js { render json: assetLinks.to_json }
        format.json { render json: assetLinks.to_json }
        format.html { render json: assetLinks.to_json }
        format.csv { send_data asset_to_csv(assetLinks), filename: "assetlinks-#{Date.today}.csv" }
      end

    else
      respond_to do |format|
        format.js { render json: AssetLink.all.to_json }
        format.json { render json: AssetLink.all.to_json }
        format.html { render json: AssetLink.all.to_json }
        format.csv { send_data asset_to_csv(AssetLink.all), filename: "assetlinks-#{Date.today}.csv" }
      end
    end
  end

  def asset
    whereclause = 'true'
    base_filename = 'assets'

    whereclause = 'is_active is true' unless params[:is_active]

    whereclause = "safecode = '#{params[:code]}'"  if params[:code]

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
    elsif not params[:code]
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
      format.json { render json: @assets.to_json }
      format.html { render json: @assets.to_json }
      format.csv { send_data asset_to_csv(@assets), filename: "#{base_filename}-#{Date.today}.csv" }
      format.gpx { send_data asset_to_gpx(@assets), filename: "#{base_filename}-#{Date.today}.gpx" }
    end
  end

  def alert
    start_time = 1.year.ago
    if params[:start_time] then 
      start_time=params[:start_time].to_time
    end
    
    alerts=Post.find_by_sql [ "select p.id, p.description as comments, p.referenced_time, p.duration, rtrim(p.site,'; ') as name, UNNEST(p.asset_codes) as reference, CAST(substring(coalesce(freq, '0') from '[0-9.]+') AS NUMERIC)*1000 as frequency, p.mode, p.callsign as activator, p.updated_at as created_time from posts p inner join items i on i.item_type='post' and i.item_id=p.id inner join users u on u.id = p.updated_by_id where i.topic_id=#{ALERT_TOPIC} and p.updated_at>'#{start_time.strftime("%Y-%m-%d %H:%M:%S")}' and ((p.referenced_date + interval '1 hours' * duration::numeric) > '#{(Time.now - 1.days).strftime("%Y-%m-%d %H:%M")}') limit 200;" ]

    if params[:zlota_only] then
     orig_alerts=alerts
     alerts=[]
     orig_alerts.each do |spot|
       a=Asset.find_by(code: alerts[:reference])
       if a and a.type.is_zlota then
         alerts+=[alerts]
       end
     end
  
    end
    respond_to do |format|
      format.js { render json: alerts.to_json }
      format.json { render json: alerts.to_json }
      format.html { render json: alerts.to_json }
      format.csv { send_data asset_to_csv(alerts), filename: "alerts-#{Time.now.strftime("%Y-%m-%dT%H:%M:%SZ")}.csv" }
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
      format.json { render json: res.to_json }
      format.html { render json: res.to_json }
    end
  end

  ###############################################################
  #                                                             #
  # APIs inherited from PnP start here                          #
  #                                                             #
  ###############################################################

  #SITES - replace this with a static file on scheduled job
  # def show_asset
  #  send_file Rails.root.join('path/to/your/file.ext'), type: 'text/html', disposition: 'inline'
  #end
  def pnp_sites
    respond_to do |format|
      format.js { send_file Rails.root.join('public/assets/sites.json'), type: 'application/json', disposition: 'inline' }
      format.json { send_file Rails.root.join('public/assets/sites.json'), type: 'application/json', disposition: 'inline' }
      format.html { send_file Rails.root.join('public/assets/sites.json'), type: 'application/json', disposition: 'inline' }
      format.csv { send_file Rails.root.join('public/assets/sites.csv'), type: 'text/csv', disposition: 'inline' }
    end
  end

  def pnp_getuserkey
    user = User.find_by(callsign: params[:callsign].upcase, pin: params[:pin].upcase)
    if user then res = user.pin else res = "FALSE" end

    respond_to do |format|
      format.js { render text: res }
      format.json { render text: res  }
      format.html { render text: res  }
    end
  end

  def pnp_check
    activations = ConsolidatedSpot.find_by_sql [ "select max(updated_at) as updated_at from consolidated_spots;" ]
    sota_activations = ConsolidatedSpot.find_by_sql [ "select max(updated_at) as updated_at from consolidated_spots where 'SOTA' = ANY(spot_type);" ]
    wwff_activations = ConsolidatedSpot.find_by_sql [ "select max(updated_at) as updated_at from consolidated_spots where 'WWFF' = ANY(spot_type);" ]
    types = {}
    ats = AssetType.find_by_sql [ "select distinct pnp_class from asset_types where name != 'all'" ]

    ats.each do |at|
      cs = ConsolidatedSpot.find_by_sql [ "select max(a.updated_at) as updated_at from assets a inner join asset_types at on at.name = a.asset_type where '#{at.pnp_class}' = at.pnp_class " ]
      types["#{at.pnp_class}"] = cs.first.updated_at.to_i
    end

    sites = Asset.find_by_sql [ "select max(updated_at) as updated_at from assets"]

    #Hand roll a PnP style CHECK result
    res = [
      { Class: "ACTIVATIONS", LastUpdate: activations.first.updated_at.to_i },
      { Class: "ActivationsLastUpdate", LastUpdate: activations.first.updated_at.to_i },
      { Class: "LastSotaActivation", LastUpdate: sota_activations.first.updated_at.to_i },
      { Class: "LastWWFFActivation", LastUpdate: wwff_activations.first.updated_at.to_i },
      { Class: "USERS", LastUpdate: 0 },
      { Class: "SITES", LastUpdate: sites.first.updated_at.to_i },
      { Class: "IOTA", LastUpdate: 1682308190 },
      { Class: "SHIRES", LastUpdate: 1781422821 },
      { Class: "PARKS", LastUpdate: types["WWFF"] }
    ]
    types.each do |t|
      res.push({Class: t.first, LastUpdate: t.last })
    end

    respond_to do |format|
      format.js { render json: res.to_json }
      format.json { render json: res.to_json }
      format.html { render json: res.to_json }
    end
  end

  def pnp_close
    lat = params[:lat]
    long = params[:long]

    asset_types = AssetType.where("name != 'all'")

    codes_arr = []
    asset_types.each do |at|
      if at.has_boundary then
      #get list of closest assets by location and boundary
      assets = Asset.find_by_sql [ %Q{ 
       SELECT code from (
         ( SELECT 
            code,
            asset_type,
            boundary <-> 'SRID=4326;POINT(#{long} #{lat})'::geometry as dist
          FROM assets 
          WHERE 
            asset_type = '#{at.name}'
          order by dist limit 10
          )
       UNION (
          SELECT 
            code,
            asset_type,
            location <-> 'SRID=4326;POINT(#{long} #{lat})'::geometry as dist
          FROM assets
          WHERE 
            asset_type = '#{at.name}'
          ORDER BY dist limit 10
          ) 
       ) AS a order by dist 
     } ]
     else
      assets = Asset.find_by_sql [ %Q{ 
          SELECT 
            code,
            asset_type,
            location <-> 'SRID=4326;POINT(#{long} #{lat})'::geometry as dist
          FROM assets
          WHERE 
            asset_type = '#{at.name}'
          ORDER BY dist limit 10
     } ]
    end
      
     if assets and assets.count>0 
       codes_arr += assets.map {|a| "'"+a.code+"'"}
     end
   end
   codes = codes_arr.uniq.join(", ") 
   if codes
     res = Asset.find_by_sql [ %Q{
     SELECT 
       a.code as id,
       a.code as "siteID",   
       at.pnp_class as "awardID",
       a.name as "siteName",
       CASE WHEN boundary is null THEN 
         CONCAT(
           Round((ST_Distance_Sphere(ST_SetSRID(ST_MakePoint(#{long}, #{lat}),4326), location)/1000)::numeric,2)::varchar,
           'km ',
           ST_CardinalDirection(ST_Azimuth(ST_SetSRID(ST_MakePoint(#{long}, #{lat}),4326), location))
         )
       ELSE
         CONCAT(
           Round((ST_Distance_Sphere(ST_SetSRID(ST_MakePoint(#{long}, #{lat}),4326), boundary)/1000)::numeric,2)::varchar,
           'km ',
           ST_CardinalDirection(ST_Azimuth(ST_SetSRID(ST_MakePoint(#{long}, #{lat}),4326), ST_ClosestPoint(boundary, ST_SetSRID(ST_MakePoint(#{long}, #{lat}),4326))))
         )
       END as "siteDistance",
       CASE WHEN boundary is null THEN 
           Round((ST_Distance_Sphere(ST_SetSRID(ST_MakePoint(#{long}, #{lat}),4326), location)/1000)::numeric,2)
       ELSE
           Round((ST_Distance_Sphere(ST_SetSRID(ST_MakePoint(#{long}, #{lat}),4326), boundary)/1000)::numeric,2)
       END as "siteDistanceNumeric"
     FROM assets a
     INNER JOIN asset_types at on at.name = a.asset_type
     WHERE a.code in (#{codes})
     ORDER by "siteDistanceNumeric"} ]
  end
#REQUIRES following function in POSTGRES
# CREATE OR REPLACE FUNCTION ST_CardinalDirection(azimuth float8) RETURNS character varying AS
# $BODY$SELECT CASE
#   WHEN $1 < 0.0 THEN 'less than 0'
#   WHEN degrees($1) < 22.5 THEN 'N'
#   WHEN degrees($1) < 67.5 THEN 'NE'
#   WHEN degrees($1) < 112.5 THEN 'E'
#   WHEN degrees($1) < 157.5 THEN 'SE'
#   WHEN degrees($1) < 202.5 THEN 'S'
#   WHEN degrees($1) < 247.5 THEN 'SW'
#   WHEN degrees($1) < 292.5 THEN 'W'
#   WHEN degrees($1) < 337.5 THEN 'NW'
#   WHEN degrees($1) <= 360.0 THEN 'N'
# END;$BODY$ LANGUAGE sql IMMUTABLE COST 100;
# COMMENT ON FUNCTION ST_CardinalDirection(float8) IS 'input azimuth in radians; returns N, NW, W, SW, S, SE, E, or NE';

    respond_to do |format|
      format.js { render json: res.to_json }
      format.json { render json: res.to_json }
      format.html { render json: res.to_json }
    end
  end

  def pnp_callsign
    res = User.find_by_sql [ %Q{select callsign as "callSign", firstname as name, '' as "alsoKnownAs", '0000-00-00' as "lastDate", '2026-06-01' as "lastUpdateDate" from users where firstname is not null and activated = true and callsign ~ '.[A-Z]+[0-9]+[A-Z]+'} ]

    respond_to do |format|
      format.js { render json: res.to_json }
      format.json { render json: res.to_json }
      format.html { render json: res.to_json }
    end
  end

  def pnp_shiresid
    lat = params[:lat]
    long = params[:long]

    #get list of closest assets by location and boundary
    shires = District.find_by_sql [ %Q{ 
      SELECT 
        CONCAT('(',substr(district_code,4),') ', name, ' [', district_code,']') AS name 
        FROM districts 
        WHERE ST_WITHIN(ST_SetSRID(ST_MakePoint(#{long}, #{lat}),4326), boundary); 
      } ]
    name = ""
    name = shires.first.name if shires and shires.count>0

    respond_to do |format|
      format.js { render text: name }
      format.json { render text: name  }
      format.html { render text: name  }
    end
  end
 
  def pnp_parkid
    lat = params[:lat]
    long = params[:long]

    #get list of closest assets by location and boundary
    res = Asset.find_by_sql [ %Q{ 
      SELECT  
          code as id,
          code, 
          name 
        FROM assets 
        WHERE ST_WITHIN(ST_SetSRID(ST_MakePoint(#{long}, #{lat}),4326), boundary) 
         OR ST_WITHIN(ST_SetSRID(ST_MakePoint(#{long}, #{lat}),4326), az_boundary); 
      } ]

    name = ""
    names = res.map {|r| "("+r.code+") "+r.name.gsub(',',';')  }
    name = names.join(", ")
    name = "Currently not within a Park" if !name or name==""

    respond_to do |format|
      format.js { render text: name }
      format.json { render text: name  }
      format.html { render text: name  }
    end
  end
 

  def pnp_sites_by_class
    dxccs = ['ZL', 'VK']
    res = []
    if params[:id].downcase == 'shires'
      res = District.generate_pnp_sites(dxccs)
    elsif params[:id].downcase == 'iota'
      res = JSON.parse(IOTA_JSON)      
    else
      asset_types = AssetType.where("pnp_class ilike '#{params[:id]}'")
      if asset_types and asset_types.count>0
        asset_type = asset_types.first
        where_query = "AND at.pnp_class = '#{asset_type.pnp_class.upcase}' "
        res = Asset.generate_pnp_sites(dxccs, where_query)
      end
    end
    respond_to do |format|
      format.js { render json: res.to_json }
      format.json { render json: res.to_json }
      format.html { render json: res.to_json }
    end
  end

  #GET SPOTS
  def pnp_all
    zone = 'OC'
    zone = params[:zone].upcase if params[:zone]
    zone_query = " and continent = '#{zone}'" if zone != 'ALL'
    duration = 520

    duration = params[:id].to_i if params[:id]
    spots=ConsolidatedSpot.where("updated_at>? #{zone_query}",duration.minutes.ago.strftime("%Y-%m-%dT%H:%M:%SZ")).order('time desc')
    res = to_pnp_spots(spots)
    respond_to do |format|
      format.js { render json: res.to_json }
      format.json { render json: res.to_json }
      format.html { render json: res.to_json }
    end
  end

  #PNP post spot
  def pnp_spot
    parstr = params.first
    parstr = parstr.first
    parstr = JSON.parse(parstr)
    params=parstr.transform_keys(&:to_sym) 
    logger.debug params.to_s
    if api_authenticate(params)
      user = User.find_by(callsign: params[:userID].upcase)
      res = { success: true, message: 'Thanks for the data!' }
      p = Post.new
      p.callsign = params[:actCallsign] || ''
      p.freq = params[:freq].to_f
      p.mode = params[:mode] || ''
      p.created_by_id = user.id
      p.updated_by_id = user.id
      p.description = params[:comments] || ''
      if !user then 
        user = User.find_by(callsign: 'GUEST') 
        p.description = p.description + ' (via '+params[:spotter]+')'
      end
      asset_code = params[:actSite] || ''
      assets = Asset.assets_from_code(asset_code)
      if !assets || assets.count.zero? || assets.first[:code].nil?
        logger.error 'Asset not known:' + asset_code + ' ... trying to continue'
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
        logger.error "Bad spot"
        res = { success: false, message: u.errors.first.to_s }
      end
    else
      logger.error "Authentication failed"
      res = { success: false, message: 'Authentication failed!' }
    end
    logger.debug res.to_json
    respond_to do |format|
      format.js { render json: res.to_json }
      format.json { render json: res.to_json }
      format.html { render json: res.to_json }
    end
  end

  def pnp_sota
    duration = 120
    duration = params[:id].to_i if params[:id]
    spots=ConsolidatedSpot.where("updated_at>? and ? = ANY(spot_type) and (dxcc = 'VK' or dxcc = 'ZL')",duration.minutes.ago, "SOTA")  
    res = to_pnp_spots(spots)
    respond_to do |format|
      format.js { render json: res.to_json }
      format.json { render json: res.to_json }
      format.html { render json: res.to_json }
    end
  end

  def pnp_wwff
    duration = 120
    duration = params[:id].to_i if params[:id]
    spots=ConsolidatedSpot.where("updated_at>? and ? = ANY(spot_type) and (dxcc = 'VK' or dxcc = 'ZL')",duration.minutes.ago, "WWFF") 
    res = to_pnp_spots(spots)
    respond_to do |format|
      format.js { render json: res.to_json }
      format.json { render json: res.to_json }
      format.html { render json: res.to_json }
    end
  end

  def pnp_vk
    spots=ConsolidatedSpot.find_by_sql [ "select * from consolidated_spots where (dxcc = 'VK' or dxcc = 'ZL') order by time desc limit 10" ]
    res = to_pnp_spots(spots)
    respond_to do |format|
      format.js { render json: res.to_json }
      format.json { render json: res.to_json }
      format.html { render json: res.to_json }
    end
  end

  def pnp_check_spots 
    spots=ConsolidatedSpot.find_by_sql [ "select * from consolidated_spots where (dxcc = 'VK' or dxcc = 'ZL') order by time desc limit 1" ]
    spot=spots.first
    res = [{ActivationsLastUpdate: spot.updated_at.to_i}]
    respond_to do |format|
      format.js { render json: res.to_json }
      format.json { render json: res.to_json }
      format.html { render json: res.to_json }
    end
  end

  def pnp_alerts
    zone = 'OC'
    zone = params[:zone].upcase if params[:zone]
    zone_query = " and continent = '#{zone}'" if zone != 'ALL'

    #need to store country in alert and use to filter here
    hota_alerts = Post.find_by_sql [ " select p.*, i.id as item_id from posts p inner join items i on i.item_id=p.id and i.topic_id=1 and i.item_type='post' and ((p.referenced_date + interval '1 hours' * duration::numeric) > '#{(Time.now - 1.days).strftime("%Y-%m-%d %H:%M")}' or p.referenced_date > '#{(Time.now - 1.days).strftime("%Y-%m-%d %H:%M")}')" ]

    all_alerts = ExternalAlert.import_hota_alerts(hota_alerts)
    if zone && (zone != 'ALL')
      all_alerts = all_alerts.select { |alert| DxccPrefix.continent_from_call(alert[:activatingCallsign]) == zone }
    end

    all_alerts += ExternalAlert.find_by_sql [ " select * from external_alerts where (starttime >'#{Time.now - 1.days}' or (starttime + interval '1 hours' * duration::numeric) >'#{Time.now - 1.days}') #{zone_query} order by starttime desc " ]

    if all_alerts then all_alerts = all_alerts.sort_by { |hsh| hsh[:starttime].to_s }.reverse! end

    res = to_pnp_alerts(all_alerts)
    respond_to do |format|
      format.js { render json: res.to_json }
      format.json { render json: res.to_json }
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

  def to_pnp_alerts(alerts)
    pnp_alerts=[]
    alerts.each do |alert|
      pnp_alert={}
      pnp_alert[:alID] = alert.id
      if alert.code.kind_of?(Array) then  codes = alert.code else codes = [alert.code] end
      pnp_alert[:WWFFID] = codes.first
      pnp_alert[:allAssetCodes] = codes
      pnp_alert[:CallSign] = alert.activatingCallsign
      pnp_alert[:Class] = alert.programme  
      pnp_alert[:Location] = alert.name
      pnp_alert[:alDay] = "0"
      pnp_alert[:alTime] = alert.starttime
      pnp_alert[:Freq] = alert.frequency
      pnp_alert[:MODE] = alert.mode
      pnp_alert[:Comments] = alert.comments
      pnp_alert[:Duration] = alert.duration
      pnp_alerts.push(pnp_alert)
    end
    pnp_alerts
  end

  def to_pnp_spots(spots)
    pnp_spots=[]
    spots.each do |spot|
      puts spot.to_json
      index = 0
      spot_count = spot.code.count
      respot_count = spot.time.count
      while index < spot_count
        pnp_spot={}
        pnp_spot[:actTime] = spot.time.last
        pnp_spot[:actID] = spot.id.to_s
        pnp_spot[:actSiteID] = spot.code[index]
        pnp_spot[:actCallsign] = spot.activatorCallsign
        pnp_spot[:actMode] = spot.mode
        pnp_spot[:actFreq] = spot.frequency
        pnp_spot[:actClass] = spot.spot_type[index]
        pnp_spot[:actLocation] = spot.name[index]
        pnp_spot[:altLocation] = ""
        pnp_spot[:actComments] = spot.comments[index]
        pnp_spot[:actSpoter] = spot.callsign[index]
        wwff_code = ""
        wwff_code = spot.code[index] if spot.code[index].match(WWFF_REGEX)
        pnp_spot[:WWFFid] = wwff_code  
        pnp_spots.push(pnp_spot)
        index += 1
      end
    end
  pnp_spots
  end
end
