# frozen_string_literal: true

# typed: false
class Post < ActiveRecord::Base
  include PostsHelper
  include MapHelper
  has_attached_file :image,
                    path: ':rails_root/public/system/:attachment/:id/:basename_:style.:extension',
                    url: '/system/:attachment/:id/:basename_:style.:extension'

  do_not_validate_attachment_file_type :image

  after_save :update_item
  before_save { before_save_actions }

  def before_save_actions
    check_codes
    location=get_most_accurate_location
    add_containing_codes
    # again to vet child codes added
    check_codes
    self.callsign = callsign.upcase if callsign
  end

  def update_item
    i = item
    if i
      i.touch
      i.save
    end
  end

  attr_accessor :x1
  attr_accessor :y1
  attr_accessor :location1
  require 'htmlentities'

  def updated_by_name
    user = User.find_by_id(updated_by_id)
    user ? user.callsign : ''
  end

  def assets
    asset_codes ? Asset.where(code: asset_codes) : []
  end

  def asset_names
    asset_names = assets.map(&:name)
    asset_names ||= ''
    asset_names
  end

  def asset_code_names
    if asset_codes
      asset_names = asset_codes.map do |ac|
        asset = Asset.assets_from_code(ac).first
        asset ? '[' + asset[:code] + '] ' + asset[:name] : ''
      end
    end
    asset_names ||= []
    asset_names
  end

  def add_map_image
    if location == nil
      puts "X,Y"
      if asset_codes
        point_loc = nil
        poly_loc = nil
        asset_codes.each do |ac|
          a = Asset.find_by(code: ac)
          if a && a.type.has_boundary
            poly_loc = { x: a.x, y: a.y } if a.location
          elsif a && a.location
            point_loc = { x: a.x, y: a.y }
          end
        end
        calc_loc = point_loc || poly_loc
      end
    else
      xyarr = transform_geom(location.x, location.y, 4326, 2193)
      calc_loc = { x: xyarr[0], y: xyarr[1] }
    end

    if calc_loc
      filename = get_map(calc_loc[:x], calc_loc[:y], 9, 'map_' + id.to_s)
      #    filename=get_map_zoomed(location[:x], location[:y], 7,15, "map_"+self.id.to_s)
      begin
        self.image = File.open(filename, 'rb')
        save
        system("rm #{filename}")
      rescue StandardError
        puts 'SAVEMAP: ERROR'
      end
    end
  end

  def images
    id ? Image.where(post_id: id) : []
  end

  def files
    #  if self.id then ufs=Uploadedfile.where(post_id: self.id) else [] end
    []
  end

  def is_file
    #    if self.image_content_type and self.image_content_type[0..10]=='application' then true else false end
    false
  end

  def is_image
    image_content_type && (image_content_type[0..4] == 'image') ? true : false
  end

  def topic_name
    topic = Topic.find_by_id(topic_id)
    topic ? topic.name : ''
  end

  def topic
    Topic.find_by_id(topic_id)
  end

  def topic_id
    topic = nil
    item = self.item
    topic = item.topic_id if item
    topic
  end

  def item
    item = nil
    items = Item.find_by_sql ["select * from items where item_type='post' and item_id=" + id.to_s]
    item = items.first if items
    item
  end

  def check_codes
    newcodes = []
    asset = nil
    asset_codes.each do |code|
      a = Asset.assets_from_code(code)
      a = a.first
      asset = a[:asset] if a && a[:asset]
      if !a && !(description || '').include?('Unknown location: ' + code)
        self.description = (description || '') + '; Unknown location: ' + code
        code = nil
      end
      newcodes += [code] if code
    end

    self.asset_codes = Asset.find_master_codes(newcodes.uniq)
  end

  def add_containing_codes
    if !do_not_lookup == true
      self.asset_codes = get_all_asset_codes if asset_codes
    end
  end

  def get_all_asset_codes
    codes = asset_codes
    newcodes = codes
    if loc_source=='user' then
      newcodes = Asset.containing_codes_from_location(location, nil, true)
    else
      codes.each do |code|
        newcodes += Asset.containing_codes_from_parent(code)
        newcodes += VkAsset.containing_codes_from_parent(code)
      end
    end
    newcodes = newcodes.uniq
    # filter out POTA / WWFF if user does not use those schemes
    user = User.find_by(callsign: callsign.upcase) if callsign
    if user && (user.logs_pota == false) then newcodes = newcodes.reject { |code| Asset.get_asset_type_from_code(code) == 'pota park' } end
    if user && (user.logs_wwff == false) then newcodes = newcodes.reject { |code| Asset.get_asset_type_from_code(code) == 'wwff park' } end
    newcodes
  end

  def send_to_all(debug, from, callsign, assets, freq, mode, description, topic, idate, itime, tzname)
    result = true
    messages = ''
    if topic && topic.is_spot
      # SPOT
      assets.each do |ac|
        asset_type = Asset.get_asset_type_from_code(ac)
        puts 'DEBUG :' + asset_type + ':'
        matched = false
        if (asset_type == 'pota park') || (asset_type == 'POTA')
          puts 'DEBUG: send ' + ac + ' to POTA'
          pota_response = send_to_pota(debug, from.callsign, callsign, ac, freq, mode, description)
          result = (result && pota_response[:result])
          messages += pota_response[:messages]
          matched = true
        elsif (asset_type == 'SOTA') || (asset_type == 'summit')
          puts 'DEBUG: send ' + ac + ' to SOTA'
          sota_response = send_to_sota(debug, from.acctnumber, callsign, ac, freq, mode, description)
          result = (result && sota_response[:result])
          messages += sota_response[:messages]
          matched = true
        elsif (asset_type == 'HEMA') || (asset_type == 'hump')
          puts 'DEBUG: send ' + ac + ' to HEMA'
          hema_response = Post.send_to_hema(debug, from.acctnumber, callsign, ac, freq, mode, description)
          result = (result && hema_response[:result])
          messages += hema_response[:messages]
        end
        next unless (result == false) || (matched == false)
        puts 'DEBUG: send ' + ac + ' to PnP'
        pnp_response = send_to_pnp(debug, ac, topic, idate, itime, tzname)
        result = (result && pnp_response[:result])
        messages += pnp_response[:messages]
      end
    else
      # ALERT so only send to PNP
      assets.each do |ac|
        pnp_response = send_to_pnp(debug, ac, topic, idate, itime, tzname)
        result = (result && pnp_response[:result])
        messages += pnp_response[:messages]
      end
    end
    { result: result, messages: messages }
  end

  def send_to_pota(debug, from, callsign, a_code, freq, mode, description)
    result = true
    messages = ''

    # is this a valid sota reference?
    asset_type = Asset.get_asset_type_from_code(a_code)

    if (asset_type == 'pota park') || (asset_type == 'POTA')

      url = URI.parse('https://api.pota.app/spot')

      a_code = 'K-TEST' if debug

      http = Net::HTTP.new(url.host, url.port)
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE

      parts = a_code.split('-')
      if parts.count == 2
        region = parts[0]
        subcode = parts[1]

        payloadspot = {
          'activator': callsign.upcase,
          'spotter': from.upcase,
          'frequency': (freq.to_f * 1000).to_s,
          'reference': region.upcase + '-' + subcode,
          'mode': mode.upcase,
          'source': 'Web',
          'comments': description
        }

        #        if debug then
        puts 'Sending SPOT to POTA'
        puts payloadspot
        #        end

        #        req = Net::HTTP::Get.new("#{url.path}?".concat(payloadspot.collect { |k,v| "#{k}=#{CGI::escape(v.to_s)}" }.join('&')), 'Content-Type' => 'application/json' )
        req = Net::HTTP::Post.new("#{url.path}?", 'Content-Type' => 'application/json')
        req.body = payloadspot.to_json
        begin
          res = http.request(req)
          puts 'DEBUG: POTA response'
          puts res.body.encode('UTF-8', invalid: :replace, undef: :replace, replace: '?')
          pspots = JSON.parse(res.body)
        rescue StandardError
          puts 'Send to POTA failed'
          result = false
          messages = 'Failed to contact POTA server'
        else
          ourspot = pspots.find { |ps| (ps['activator'] == callsign.upcase) && (ps['reference'] == region.upcase + '-' + subcode) && (ps['mode'] == mode.upcase) && ((ps['frequency']).to_i == (freq.to_f * 1000).to_i) }
          if !ourspot
            result = false
            puts 'DUBUG: spot not accepted by POTA'
            messages = 'Spot not accepted by POTA for: ' + a_code + '; '
          else
            messages = 'Sent spot to POTA; '
          end
        end
      else
        puts 'Invalid POTA code: ' + a_code
        messages = 'Invalid POTA code: ' + a_code + '; '
        result = false
      end
    elsif debug
      puts 'Not a POTA asset: ' + a_code
      messages = 'Not a POTA asset: ' + a_code + '; '
      result = false
    end
    { result: result, messages: messages }
  end

  def self.send_to_hema(_debug, _from, callsign, a_code, freq, mode, _description)
    result = false
    messages = ''
    asset = Asset.find_by(code: a_code)
    asset_type = Asset.get_asset_type_from_code(a_code)
    if asset && ((asset_type == 'hump') || (asset_type == 'HEMA'))
      modes = { 'AM' => 1, 'FM' => 2, 'CW' => 3, 'SSB' => 4, 'USB' => 4, 'LSB' => 4, 'DATA' => 7, 'OTHER' => 9 }
      mode = mode.upcase
      modekey = modes[mode]
      modekey ||= 7
      puts modekey, mode

      params = '?number=' + asset.old_code + '&frequency=' + freq.to_s + '&callsign=' + callsign + '&modeKey=' + modekey.to_s + '&seededPair=2C1CD544EC774B90884839AC4DECEB9F2E2638EABBFF4CEB8B4085AE1CD26283'

      puts 'sending spot to HEMA'
      uri = URI('http://www.hema.org.uk/submitMobileSpot.jsp')
      puts 'DEBUG: http://www.hema.org.uk/submitMobileSpot.jsp' + params
      http = Net::HTTP.new(uri.host, uri.port)
      req = Net::HTTP::Get.new(uri.path + params)
      begin
        response = http.request(req)
        result = true if response
      rescue StandardError
        messages = 'Failed to contact HEMA server'
      else
        messages = 'Sent spot to HEMA; '
        puts response
        puts response.body
      end
    end
    { result: result, messages: messages }
  end

  def send_to_sota(debug, from, callsign, a_code, freq, mode, description)
    result = true
    messages = ''

    # is this a valid sota reference?
    asset_type = Asset.get_asset_type_from_code(a_code)
    puts ':' + asset_type + ':'
    if (asset_type == 'SOTA') || (asset_type == 'summit')

      jscreds = Keycloak::Client.get_token(SOTA_USER, SOTA_PASSWORD, SOTA_CLIENT_ID, SOTA_SECRET)
      creds = JSON.parse(jscreds)
      access_token = creds['access_token']
      id_token = creds['id_token']

      if debug
        puts 'DEBUG'
        url = URI.parse('https://cluster.sota.org.uk:8150/testme')
      else
        puts 'LIVE'
        url = URI.parse('https://cluster.sota.org.uk:8150/spotme')
      end

      http = Net::HTTP.new(url.host, url.port)
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE

      parts = a_code.split('/')
      if parts.count == 2
        region = parts[0]
        subcode = parts[1]

        #workaround - add .0 to integer frequencies
        if freq and !freq.blank? and !freq.include?('.') then freq=freq.to_i.to_s+".0" end
        payloadspot = {
          'To': '+64273105319',
          'MessageTime': Time.now.utc.strftime('%a %b %d %H:%M:%S %Y'),
          'From': from,
          'MessageSid': 'SMS_ZL',
          'Body': callsign + ' ' + region + ' ' + subcode + ' ' + freq + ' ' + mode + ' ' + description
        }

        if debug
          puts 'Sending SPOT to SOTA'
          puts payloadspot
        end

        req = Net::HTTP::Get.new("#{url.path}?"+(payloadspot.collect { |k, v| "#{k}=#{CGI.escape(v.to_s)}" }.join('&')), 'Content-Type' => 'application/json', 'Authorization' => 'bearer ' + access_token, 'id_token' => id_token, 'connection' => 'keep-alive')
        begin
          res = http.request(req)
        rescue StandardError
          puts 'Send to SOTA failed'
          result = false
          messages = 'Failed to contact SOTA server'
        else
          messages = 'Sent spot to SOTA; '
          puts 'DEBUG: SOTA response'
          puts res.body
        end
      else
        puts 'Invalid SOTA code: ' + a_code
        messages = 'Invalid SOTA code: ' + a_code + '; '
        result = false
      end
    elsif debug
      puts 'Not a SOTA asset: ' + a_code
      messages = 'Not a SOTA asset: ' + a_code + '; '
      result = false
    end
    { result: result, messages: messages }
  end

  def send_to_pnp(debug, ac, topic, idate, itime, tzname)
    result = false
    messages = ''
    dbtext = debug ? '/DEBUG' : ''
    puts 'DEBUG status: ' + dbtext
    if topic && topic.is_alert
      dayflag = itime && !itime.empty? ? false : true
      dt = (idate || '') + ' ' + (itime || '')
      if dt && (dt.length > 1)
        if dayflag
          tt = dt.in_time_zone('UTC')
        elsif tzname == 'UTC'
          tt = dt.in_time_zone('UTC')
        else
          tt = dt.in_time_zone('Pacific/Auckland')
          tt = tt.in_time_zone('UTC')
        end
      end

      puts 'sending alert(s) to PnP'

      code = ac.split(']')[0]
      code = code.delete('[')
      pnp_class = Asset.get_pnp_class_from_code(code)
      if pnp_class && (pnp_class != '')
        puts 'sending alert to PnP'
        params = { 'actClass' => pnp_class, 'actCallsign' => updated_by_name, 'actSite' => code, 'actMode' => mode.strip, 'actFreq' => freq.strip, 'actComments' => convert_to_text(description), 'userID' => 'ZLOTA', 'APIKey' => '4DDA205E08D2', 'alDate' => tt ? tt.strftime('%Y-%m-%d') : '', 'alTime' => tt ? tt.strftime('%H:%M') : '', 'optDay' => dayflag ? '1' : '0' }
        uri = URI('http://parksnpeaks.org/api/ALERT' + dbtext)
        http = Net::HTTP.new(uri.host, uri.port)
        req = Net::HTTP::Post.new(uri.path, 'Content-Type' => 'application/json')
        req.body = params.to_json
        begin
          response = http.request(req)
        rescue StandardError
          messages = 'Failed to contact PnP server'
        else
          messages = 'Sent to PnP; '
          puts response
          puts response.body
        end
      end
    end
    if topic.is_spot
      code = ac.split(']')[0]
      code = code.delete('[')
      pnp_class = Asset.get_pnp_class_from_code(code)
      if pnp_class && (pnp_class != '')
        params = { 'actClass' => pnp_class, 'actCallsign' => (callsign || updated_by_name), 'actSite' => code, 'mode' => mode.strip, 'freq' => freq.strip, 'comments' => convert_to_text(description), 'userID' => 'ZLOTA', 'APIKey' => '4DDA205E08D2' }
        puts 'sending spot to PnP'
        uri = URI('http://parksnpeaks.org/api/SPOT' + dbtext)
        puts 'DEBUG: http://parksnpeaks.org/api/SPOT' + dbtext
        http = Net::HTTP.new(uri.host, uri.port)
        req = Net::HTTP::Post.new(uri.path, 'Content-Type' => 'application/json')
        req.body = params.to_json
        begin
          response = http.request(req)
        rescue StandardError
          messages = 'Failed to contact PnP server'
        else
          messages = 'Sent to PnP; '
          puts response
          puts response.body
        end
      end
    end
    if response && (response != '')
      result = true
      debugstart = response.body.index('received')
      debugfail = response.body.index('Failure')
      if debugfail
        puts 'DEBUG: Send to PnP recieved failed'
        result = false
      end
      if debugstart
        messages = 'PnP responsed with: ' + response.body[debugstart..-1]
      end
    else
      if !messages || (messages == '') then messages = 'Failed to send ' + ac + ' to PnP. Did you specify a valid place, frequency, mode & callsign?; ' end
      result = false
    end

    { result: result, messages: messages }
  end

  def get_most_accurate_location
    if loc_source!='user'
      location = nil
      loc = Asset.get_most_accurate_location(asset_codes)
      location = loc[:location] if loc
      location
    else
      location = self.location
    end
  end
end
