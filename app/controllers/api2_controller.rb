# frozen_string_literal: false

# typed: false
class Api2Controller < ApplicationController
  VALID_CALLSIGN_REGEX = '.[A-Z]+[0-9]+[A-Z]+'

  include PostsHelper

  require 'rexml/document'
  require 'asset_import_tools'

  skip_before_filter :verify_authenticity_token

  def index; end

  # API: ======================================================================================
  # API:
  # API: /api2/users/verify   -  Retrieve latest spots
  # API:       Parameters:
  # API:         userID     - user's login callsign 
  # API:         APIKey     - user's PIN or PnP APIKEY
  # API:       Returns:  
  # API:         success    - true / false
  # API:         messages   - Reasons for failure (string) or ""
  def pnp_users_verify
    if params[:userID] and params[:APIKey] then
      user=User.find_by(callsign: params[:userID].upcase, pin: params[:APIKey].upcase)
    end

    if user then 
       res = {success: true, messages: ""}
    else
       res = {success: false, messages: "Callsign / PIN combination do not match our records"}
    end
    render json: res
  end

  # API: ======================================================================================
  # API:
  # API: /api2/users/index   -  Retrieve user to name mappings
  # API:       Parameters:   none
  # API:       Returns:  
  # API:         callsign    - callsign
  # API:         name        - first name
  # API:       Note: Does not currently include secondary callsigns
  def pnp_users_index
    res = User.find_by_sql [ %Q{select callsign as callsign, firstname as name from users where firstname is not null and activated = true and callsign ~ '#{VALID_CALLSIGN_REGEX}';} ]

    render json: res.to_json 
  end

  # API: ======================================================================================
  # API:
  # API: /api2/spots/index   -  Retrieve latest spots
  # API:       Parameters:
  # API:         continent  - Filter by continent  
  # API:           values   - OC/NA/SA/AN/EU/AS/AF/ALL (default: ALL)
  # API:         max_age    - how many minutes before now to return
  # API:           values   - (integer) (default: 120)
  # API:       Returns:  
  # API:         spotID     - unique identifier
  # API:         updatedAt  - last spot time (timestamp)
  # API:         activatorCallsign
  # API:                    - callsign of activator (string)
  # API:         lastSpotterCallsign
  # API:                    - callsign of most recent spotter (string)
  # API:         frequency  - frequency (float)
  # API:         mode       - mode (string)
  # API:         band       - band by wavelength (string)
  # API:         dxcc       - DXCC prefix (string)
  # API:         continent  - 2-letter continent code (string)
  # API:         location   - Array of location data
  # API:           values   - [[reference1, award_class1, site_name1], [reference2... ]]
  # API:         comments   - Array of comments from all spots & re-spots, oldest first
  # API:           values   - [comment1, comment2, comment2 ...]
  # API:       e.g:
  # API:         https://ontheair.nz/api2/spots/index?max_age=20&continent=NA
  def pnp_spots_index
    zone = 'ALL'
    zone = params[:continent].upcase if params[:continent]
    duration = 120

    duration = params[:max_age].to_i if params[:max_age]
    start_time = duration.minutes.ago.utc.iso8601
    res = ConsolidatedSpot.get_pnp2_spots(start_time, zone)
    
    render json: res.to_json
  end

  # API: ======================================================================================
  # API:
  # API: /api2/spots/check  - Get last update time for selected spots
  # API:       Parameters:
  # API:         continent  - Filter by continent  
  # API:           values   - OC/NA/SA/AN/EU/AS/AF/ALL (default: ALL)
  # API:       Returns:  
  # API:         lastUpdatedAt       - last spot time (integer: seconds since epoch)
  def pnp_spots_check
    zone = 'ALL'
    zone = params[:continent].upcase if params[:continent]
    res = ConsolidatedSpot.check_pnp2_spots(zone)
   
    render json: res.to_json
  end

  # API: ======================================================================================
  # API:
  # API: /api2/spots/create -  Create a spot (POST or GET)
  # API:       Parameters:
  # API:         userID  :  - login callsign (for authentication)
  # API:         APIKey:    - login PIN or PnP APIKEY for authentication
  # API:         activatorCallsign
  # API:                    - callsign of activator (string)
  # API:         spotterCallsign
  # API:                    - callsign of spotter (string) - defaults to current user's callsign
  # API:         frequency  - frequency (float)
  # API:         mode       - mode (string)
  # API:         location   - reference code(s), comma separated if multiple
  # API:                      the forward-slash '/' can be substituted with '_' if required
  # API:         comments   - comment
  # API:         do_not_lookup - true: Create spot only for the reference(s) posted, do not
  # API:                               look up and include containing parks, etc
  # API:                         false: Include all containing parks, etc in the spot
  # API:         debug         - true: Create spot in 'test spots' category, do not publish
  # API:       Returns:  
  # API:         success    - true / false
  # API:         messages   - Reasons for failure (string) or ""
  def pnp_spots_create
    if api_authenticate(params)
      user = User.find_by(callsign: params[:userID].upcase)
      res = { success: true, message: 'Thanks for the data!' }
      p = Post.new
      p.callsign = params[:activatorCallsign] || ''
      p.callsign = p.callsign.upcase
      p.freq = params[:frequency].to_f/1000
      p.mode = params[:mode] || ''
      p.created_by_id = user.id
      p.updated_by_id = user.id
      p.description = params[:comments] || ''
      if !user then 
        user = User.find_by(callsign: 'GUEST') 
        p.description = p.description + ' (via '+params[:spotterCallsign]+')'
      end
      asset_code = params[:location] || ''
      asset_code = asset_code.gsub('_','/')
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
      debug = false 
      if params[:debug] then debug=true end
      p.asset_codes=a_code != '' ? a_codes : []
      debug = true if p.description.upcase['DEBUG'] 
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

  # API: ======================================================================================
  # API:
  # API: /api2/alerts/index - Retrieve all alerts
  # API:       Parameters:
  # API:         continent  - Filter by continent  
  # API:           values   - OC/NA/SA/AN/EU/AS/AF/ALL (default: ALL)
  # API:       Returns:  
  # API:         alertID     - unique identifier
  # API:         activatorCallsign
  # API:                    - callsign of activator (string)
  # API:         frequency  - frequency (float)
  # API:         mode       - mode (string)
  # API:         dxcc       - DXCC prefix (string)
  # API:         continent  - 2-letter continent code (string)
  # API:         location   - Array of location data
  # API:           values   - [[reference1, award_class1, site_name1], [reference2... ]]
  # API:         comments   - comments (string)
  # API:       e.g:
  # API:         https://ontheair.nz/api2/alerts/index?continent=NA
  def pnp_alerts_index
    zone = 'ALL'
    zone = params[:continent].upcase if params[:continent]
    zone_query = " and continent = '#{zone}'" if zone != 'ALL'

    #need to store country in alert and use to filter here
    hota_alerts = Post.find_by_sql [ " select p.*, i.id as item_id from posts p inner join items i on i.item_id=p.id and i.topic_id=1 and i.item_type='post' and ((p.referenced_date + interval '1 hours' * duration::numeric) > '#{(Time.now - 1.days).strftime("%Y-%m-%d %H:%M")}' or p.referenced_date > '#{(Time.now - 1.days).strftime("%Y-%m-%d %H:%M")}')" ]

    all_alerts = ExternalAlert.import_hota_alerts(hota_alerts)
    if zone && (zone != 'ALL')
      all_alerts = all_alerts.select { |alert| DxccPrefix.continent_from_call(alert[:activatingCallsign]) == zone }
    end

    all_alerts += ExternalAlert.find_by_sql [ " select * from external_alerts where (starttime >'#{Time.now - 1.days}' or (starttime + interval '1 hours' * duration::numeric) >'#{Time.now - 1.days}') #{zone_query} order by starttime desc " ]

    if all_alerts then all_alerts = all_alerts.sort_by { |hsh| hsh[:starttime].to_s }.reverse! end

    res = to_pnp2_alerts(all_alerts)
    render json: res.to_json
  end

  # API: ======================================================================================
  # API:
  # API: /api2/alerts/create - Create an alert
  # API:       Parameters:
  # API:         userID  :  - login callsign (for authentication)
  # API:         APIKey:    - login PIN or PnP APIKEY for authentication
  # API:         activatorCallsign
  # API:                    - callsign of activator (string)
  # API:         frequency  - frequency (float)
  # API:         mode       - mode (string)
  # API:         date       - activation date (string - YYYY-MM-DD) (UTC)
  # API:         time       - activation time (string - HH:MM) (UTC)
  # API:         location   - reference code(s), comma separated if multiple
  # API:                      the forward-slash '/' can be substituted with '_' if required
  # API:         comments   - comment
  # API:         do_not_lookup - true: Create spot only for the reference(s) posted, do not
  # API:                               look up and include containing parks, etc
  # API:                         false: Include all containing parks, etc in the spot
  # API:         debug         - true: Create spot in 'test spots' category, do not publish
  # API:       Returns:  
  # API:         success    - true / false
  # API:         messages   - Reasons for failure (string) or ""
  def pnp_alerts_create 
    if api_authenticate(params)
      user = User.find_by(callsign: params[:userID].upcase)
      res = { success: true, message: 'Feature not yet supported' }
    else
      puts "Authentication failed"
      res = { success: false, message: 'Authentication failed!' }
      p = Post.new
      p.callsign = params[:activatorCallsign] || ''
      p.freq = params[:frequency].to_f
      p.mode = params[:mode] || ''
      p.created_by_id = user.id
      p.updated_by_id = user.id
      p.description = params[:comments] || ''
      asset_code = params[:location] || ''
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
      debug = false 
      if params[:debug] then debug=true end
      p.asset_codes=a_code != '' ? a_codes : []
      debug = true if p.description.upcase['DEBUG'] 
      al_date = params[:date]
      al_time = params[:time]
      p.referenced_time = (al_date + ' ' + al_time + ' UTC').to_time
      p.referenced_date = (al_date + ' 00:00:00 UTC').to_time
      p.updated_at = Time.now
      p.title = 'ALERT: ' + p.callsign + ' going portable at ' + a_name + '[' + a_code + '] on ' + p.freq.to_s + '/' + p.mode + ' at ' + p.referenced_time.strftime('%Y-%m-%d %H:%M') + 'UTC'
      topic_id = if debug
                       TEST_ALERT_TOPIC
                     else
                       ALERT_TOPIC
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
        logger.error "Bad alert"
        res = { success: false, message: u.errors.first.to_s }
      end
    end
    respond_to do |format|
      format.js { render json: res.to_json }
      format.json { render json: res.to_json }
      format.html { render json: res.to_json }
    end
  end

  # API: ======================================================================================
  # API:
  # API: /api2/alerts/delete - Delete an alert
  # API:       Parameters:  TODO
  def pnp_alerts_delete
    if api_authenticate(params)
      user = User.find_by(callsign: params[:userID].upcase)
      res = { success: true, message: 'Feature not yet supported' }
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


  # API: ======================================================================================
  # API:
  # API: /api2/sites/check - Get last update time for sites data
  # API:       Parameters:
  # API:       Returns:  
  # API:         siteClass           - last spot time (integer: seconds since epoch)
  # API:         lastUpdatedAt       - last spot time (integer: seconds since epoch)
  def pnp_sites_check
    # Fetch all max updated_at timestamps grouped by pnp_class in a single query
    results = Asset.find_by_sql [ %Q{
      SELECT at.pnp_class as "siteClass",  round(EXTRACT(EPOCH FROM MAX(a.updated_at))::numeric,0) AS "lastUpdatedAt"
       FROM assets a 
       INNER JOIN asset_types at ON at.name = a.asset_type 
       WHERE at.name != 'all' 
       GROUP BY at.pnp_class}
    ]

    render json: results.to_json 
  end

  # API: ======================================================================================
  # API:
  # API: /api2/sites/index - Get site data for specified class
  # API:       Parameters:
  # API:         dxcc      - Filter by dxcc  (ZL/VK/ALL) (default: ALL)
  # API:         siteClass - Filter by award class of the site (WWFF, POTA, ZLOTA, SOTA, HEMA. LLOTA,
  # API:                     SIOTA, ZLOTA)
  # API:       Returns:  
  # API:         name                - site name
  # API:         latitude            - site latitude (WGS 84 decimal degrees)
  # API:         longitude           - site longitude (WGS 84 decimal degrees)
  # API:         siteId              - site reference code
  # API:         award               - site award programme
  # API:         class               - class of site within award programme
  # API:         region              - SOTA region
  # API:         district            - Shire / local govt district code
  # API:         state               - State / territory / island code
  # API:         country             - DXCC prefix of country
  # API:         continent           - 2-letter code for continent
  # API:         contains            - Array of other sites geographically contained by this one
  # API:            - values             [[ siteCode, award ], [ siteCode, award] ... ]
  # API:         containedBy         - Array of other sites which geographically contain this site
  # API:            - values             [[ siteCode, award ], [ siteCode, award] ... ]
  # API:         equivalentTo        - Array of other sites which are geographically equivalent to this site
  # API:            - values             [[ siteCode, award ], [ siteCode, award] ... ]
  def pnp_sites_index
    dxccs = ['ZL', 'VK']
    dxccs = [params[:dxcc].upcase] if params[:dxcc] and params[:dxcc]!='ALL' and params[:dxcc]!='all'
    res = []
    asset_types = AssetType.where("pnp_class ilike ?", params[:siteClass].upcase)
    if asset_types and asset_types.count>0
      asset_type = asset_types.first
      where_query = asset_type.pnp_class.upcase
      res = Asset.generate_pnp2_sites(dxccs, where_query)
    end
    render json: res.to_json.gsub('/', '\\/')
  end

  # API: ======================================================================================
  # API:
  # API: /api2/sites/nearby - Get details of sites near to specified location
  # API:                      Returns the 10 closest sites in each award class
  # API:       Parameters:
  # API:         latitude  - Y Location (WGS84 decimal degrees)
  # API:         longitude - X Location (WGS84 decimal degrees)
  # API:         limit     - Number of sites to return in each class. Default: 10, Max: 20
  # API:       Returns:  
  # API:         name                - site name
  # API:         siteId              - site reference code
  # API:         award               - site award programme
  # API:         siteDistance        - distance to site boundary or location, kilometers
  # API:         siteDirecion        - direction of site (N, NE, E, SE, S, SW, W, NW or "")
  def pnp_sites_nearby
   logger.debug "Incoming request: #{request.format}" 
    lat = params[:latitude]
    long = params[:longitude]
    limit = 10
    limit = params[:limit].to_i if params[:limit]
    limit = 20 if limit >20
    
    res = Asset.get_pnp2_close(lat, long, limit)

    render json: res.to_json 
  end

  # API: ======================================================================================
  # API:
  # API: /api2/sites/within - Get details of sites the location is within the boundary or AZ of
  # API:       Parameters:
  # API:         latitude  - Y Location (WGS84 decimal degrees)
  # API:         longitude - X Location (WGS84 decimal degrees)
  # API:       Returns:  
  # API:         name                - site name
  # API:         siteId              - site reference code
  # API:         award               - site award programme
  # API:         class               - category within site award programme
  # API:         siteDistance        - distance to site boundary or location, kilometers
  # API:         siteDirecion        - direction of site (N, NE, E, SE, S, SW, W, NW or "")
  def pnp_sites_within
    lat = params[:latitude]
    long = params[:longitude]

    res = Asset.get_pnp_within(lat, long)
    render json: res.to_json
  end

  # API: ======================================================================================
  # API:
  # API: /api2/districts/index - Get disricts data for specified dxcc
  # API:       Parameters:
  # API:         dxcc      - Filter by dxcc  (ZL/VK/ALL) (default: ALL)
  # API:       Returns:  
  # API:         name                - district name
  # API:         latitude            - district latitude (WGS 84 decimal degrees)
  # API:         longitude           - district longitude (WGS 84 decimal degrees)
  # API:         districtID          - code for this district
  # API:         shireID             - shire code for this district (VK only)
  # API:         regionID            - SOTA region for this district (mid-point)
  # API:         stateID             - State / territory / island code for this district
  # API:         dxccPrefix          - DXCC prefix used for this district
  # API:         countryID           - ISO code for this country
  # API:         continent           - 2-letter code for continent
  def pnp_districts_index
    dxccs = ['ZL', 'VK']
    dxccs = [params[:dxcc].upcase] if params[:dxcc] and params[:dxcc]!='ALL' and params[:dxcc]!='all'

    res = District.generate_pnp2_sites(dxccs)

    render json: res.to_json
  end

  # API: ======================================================================================
  # API:
  # API: /api2/districts/within - Get details of districts, regions etc for a location
  # API:       Parameters:
  # API:         latitude  - Y Location (WGS84 decimal degrees)
  # API:         longitude - X Location (WGS84 decimal degrees)
  # API:       Returns:  
  # API:         name                - district name
  # API:         districtID          - code for this district
  # API:         shireID             - shire code for this district (VK only)
  # API:         regionID            - SOTA region for this district (mid-point)
  # API:         stateID             - State / territory / island code for this district
  # API:         dxccPrefix          - DXCC prefix used for this district
  # API:         countryID           - ISO code for this country
  # API:         continent           - 2-letter code for continent
  def pnp_districts_within
    lat = params[:latitude]
    long = params[:longitude]

    #get list of closest assets by location and boundary
    res = District.get_pnp2_districts(lat, long)
    render json: res.to_json
  end

  # API: ======================================================================================
  # API:
  # API: /api2/regions/index - Get regions data for specified dxcc
  # API:       Parameters:
  # API:         dxcc      - Filter by dxcc  (ZL/VK/ALL) (default: ALL)
  # API:       Returns:  
  # API:         name                - region name
  # API:         latitude            - region latitude (WGS 84 decimal degrees)
  # API:         longitude           - region longitude (WGS 84 decimal degrees)
  # API:         regionID            - SOTA region code
  # API:         stateID             - State / territory / island code for this region
  # API:         dxccPrefix          - DXCC prefix used for this region
  # API:         countryID           - ISO code for this country
  # API:         continent           - 2-letter code for continent
  def pnp_regions_index
    dxccs = ['ZL', 'VK']
    dxccs = [params[:dxcc].upcase] if params[:dxcc] and params[:dxcc]!='ALL' and params[:dxcc]!='all'

    res = Region.generate_pnp2_sites(dxccs)

    render json: res.to_json
  end

  # API: ======================================================================================
  # API:
  # API: /api2/states/index - Get states data for specified dxcc
  # API:       Parameters:
  # API:         dxcc      - Filter by dxcc  (ZL/VK/ALL) (default: ALL)
  # API:       Returns:  
  # API:         name                - state name
  # API:         latitude            - state latitude (WGS 84 decimal degrees)
  # API:         longitude           - state longitude (WGS 84 decimal degrees)
  # API:         stateID             - State / territory / island code 
  # API:         stateCode           - Alternative format State / territory / island code
  # API:         dxccPrefix          - DXCC prefix used for this state
  # API:         countryID           - ISO code for this country
  # API:         continent           - 2-letter code for continent
  def pnp_states_index
    dxccs = ['ZL', 'VK']
    dxccs = [params[:dxcc].upcase] if params[:dxcc] and params[:dxcc]!='ALL' and params[:dxcc]!='all'

    res = State.generate_pnp2_sites(dxccs)

    render json: res.to_json
  end

  # API: ======================================================================================
  # API:
  # API: /api2/countries/index - Get countries data 
  # API:       Parameters:
  # API:       Returns:  
  # API:         name                - country name
  # API:         prefix              - DXCC prefix used for this country
  # API:         iso_code            - ISO code for this country
  # API:         continent           - 2-letter code for continent
  # API:         itu_zone            - ITU zone
  # API:         cq_zone             - CQ zone
  
  def pnp_countries_index
    res = DxccPrefix.all

    render json: res.to_json
  end

  # API: ======================================================================================
  # API:
  # API: /api2/continents/index - Get continents data
  # API:       Parameters:
  # API:       Returns:  
  # API:         name                - continent name
  # API:         code                - 2-letter code for continent
  def pnp_continents_index
    res = Continent.all

    render json: res.to_json
  end


  # API:
  # API:
  # API: /api2/logs/create - Upload a log (POST)
  # API:       Parameters:
  def pnp_logs_create
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

  def assettype
    respond_to do |format|
      format.js { render json: AssetType.all.to_json }
      format.json { render json: AssetType.all.to_json }
      format.html { render json: AssetType.all.to_json }
      format.csv { send_data asset_to_csv(AssetType.all), filename: "assettypes-#{Date.today}.csv" }
    end
  end


  ###############################################################
  #                                                             #
  # APIs inherited from PnP start here                          #
  #                                                             #
  ###############################################################



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

  def to_pnp2_alerts(alerts)
    pnp_alerts=[]
    alerts.each do |alert|
      pnp_alert={}
      pnp_alert[:alertID] = alert.id
      if alert.code.kind_of?(Array) then  codes = alert.code else codes = [alert.code] end
      locations = []
      codes.each do |code|
        aa = Asset.assets_from_code(code)
        if aa and aa.count>0 
          a = aa.first 
          types = AssetType.find_by(name: a[:type])
          if types then 
            type = types.pnp_class
          else
            type = Asset.self.get_pnp_class_from_code(code)
          end
          locations.push(code, type, a[:name])
        else
          type = Asset.get_pnp_class_from_code(code)
          locations.push(code, type, code)
        end
      end
      pnp_alert[:location] = locations
      pnp_alert[:activatorCallSign] = alert.activatingCallsign
      pnp_alert[:time] = alert.starttime.strftime("%Y-%m-%d %H:%M:%S")
      pnp_alert[:frequency] = alert.frequency
      pnp_alert[:mode] = alert.mode
      pnp_alert[:comments] = alert.comments
      pnp_alert[:duration] = alert.duration
      pnp_alert[:dxcc] = alert.dxcc
      pnp_alert[:continent] = alert.continent
      pnp_alerts.push(pnp_alert)
    end
    pnp_alerts
  end

end
