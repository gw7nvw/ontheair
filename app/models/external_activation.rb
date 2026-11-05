# frozen_string_literal: true

# typed: false

class ExternalActivation < ApplicationRecord
  before_save { before_save_actions }
  include AssetImportTools

  def before_save_actions
    remove_call_suffix
    add_user_ids
  end

  def add_user_ids
    # look up callsign1 at contact.time
    user = User.find_by_callsign_date(callsign, date, true)
    self.user_id = user.id if user
  end

  def remove_call_suffix
    self.callsign = User.remove_call_suffix(callsign) if callsign["/"]
  end

  def self.import_next_sota
    last_code=""
    as = AdminSettings.first
    last_code = as.last_sota_update_id if as
    summits = Asset.find_by_sql [ "select * from assets where asset_type='summit' and code > '#{last_code}' order by code limit 1" ]
    if summits and summits.count>0
      summit = summits.first
      puts "DEBUG:  Update #{summit.code} from SOTA"
      update_sota_activation(summit)
      as.update_attribute(:last_sota_update_id, summit.code)
    else
      # end of list, trigger restart and mark pass as done
      as.update_attribute(:last_sota_update_id, "")
      as.update_attribute(:last_sota_activation_update_at, Time.now)
    end
  end

  def self.import_next_pota
    last_code=""
    as = AdminSettings.first
    last_code = as.last_pota_update_id if as
    summits = Asset.find_by_sql [ "select * from assets where asset_type='pota park' and code > '#{last_code}' order by code limit 1" ]
    if summits and summits.count>0
      summit = summits.first
      update_pota_activation(summit)
      puts "DEBUG:  Update #{summit.code} from POTA"
      as.update_attribute(:last_pota_update_id, summit.code)
    else
      # end of list, trigger restart and mark pass as done
      as.update_attribute(:last_pota_update_id, "")
      as.update_attribute(:last_pota_update_at, Time.now)
    end
  end

  def self.import_next_wwff
    last_code=""
    as = AdminSettings.first
    last_code = as.last_wwff_update_id if as
    summits = Asset.find_by_sql [ "select * from assets where asset_type='wwff park' and code > '#{last_code}' order by code limit 1" ]
    if summits and summits.count>0
      summit = summits.first
      update_wwff_activation(summit)
      puts "DEBUG:  Update #{summit.code} from WWFF"
      as.update_attribute(:last_wwff_update_id, summit.code)
    else
      # end of list, trigger restart and mark pass as done
      as.update_attribute(:last_wwff_update_id, "")
      as.update_attribute(:last_wwff_update_at, Time.now)
    end
  end

  def self.import_sota
    summits = Asset.where(asset_type: "summit")
    summits.each do |summit|
      update_sota_activation(summit)
    end
  end

  def self.import_pota
    summits = Asset.where(asset_type: "pota park").order(:code)
    summits.each do |summit|
      update_pota_activation(summit)
    end
  end

  def self.import_wwff
    summits = Asset.where(asset_type: "wwff park").order(:code)
    summits.each do |summit|
      update_wwff_activation(summit)
    end
  end

  def self.update_sota_activation(summit, only_new = true)
    # log in

    jscreds = Keycloak::Client.get_token(
       Rails.application.credentials.sota_user,
       Rails.application.credentials.sota_password,
       "sotadata",
       Rails.application.credentials.sota_secret)
    creds = JSON.parse(jscreds)
    access_token = creds["access_token"]
    refresh_token = creds["refresh_token"] # <- Grab the refresh token

    # id_token = creds['id_token']

    begin
      activation_ids = []
      puts "Summit: " + summit.code
      url = URI.parse("https://api-db2.sota.org.uk/api/activations/" + summit.code)
      http = Net::HTTP.new(url.host, url.port)
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE

      req = Net::HTTP::Get.new(url.path.to_s, "Content-Type" => "application/json", "Authorization" => "Bearer " + access_token, "connection" => "keep-alive")
      req["User-Agent"] = USER_AGENT_STRING
      res = http.request(req)
      data = JSON.parse(res.body)

      if data && data.count.positive?
        puts "Activations: " + data.count.to_s
        newcount = 0
        data.each do |activation|
          sa = ExternalActivation.new
          sa.asset_type = "summit"
          sa.external_activation_id = activation["id"].to_i
          sa.callsign = User.remove_call_suffix(activation["ownCallsign"].strip)
          if sa.callsign then
            puts "Activator: #{sa.callsign}"
            sa.summit_code = summit.code.strip
            if activation["activationDate"] then sa.date = activation["activationDate"].to_date.strftime("%Y-%m-%d") end
            sa.qso_count = activation["qsos"]
            activation_ids += [ activation["id"] ] if !only_new # triggers chaser check for all activations
            dups = ExternalActivation.where(external_activation_id: sa.external_activation_id).count
            if dups.zero?
              activation_ids += [ activation["id"] ] if only_new # triggers chaser check for new activations only
              puts "#{sa.callsign}  New!"
              newcount += 1
              sa.save
              user = User.find_by(callsign: sa.callsign)
              user ||= User.create(callsign: sa.callsign, activated: false, password: "dummy", password_confirmation: "dummy", timezone: 1)
              if user
                if Rails.env.production?
                  user.outstanding = true
                  user.save
                  Resque.enqueue(Scorer)
                else
                  user.update_score
                  user.check_awards
                  user.check_completion_awards("district")
                  user.check_completion_awards("region")
                end
              end
            end
          end
          puts "New: " + newcount.to_s
        end
      end

      # get chasers
      activation_ids.each do |aid|
        url = URI.parse("https://api-db2.sota.org.uk/logs/whochasedme/" + aid.to_s)
        http = Net::HTTP.new(url.host, url.port)
        http.use_ssl = true
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE

        req = Net::HTTP::Get.new(url.path.to_s, "Content-Type" => "application/json", "Authorization" => "Bearer " + access_token, "connection" => "keep-alive")
        req["User-Agent"] = USER_AGENT_STRING
        res = http.request(req)
        data = JSON.parse(res.body)
        if data && data["chases"]
          if data["summary"] && data["summary"].count.positive?
            actdate = data["summary"].first["ActivationDate"]
            puts "chases: " + data["chases"].count.to_s
            newcount = 0
            data["chases"].each do |chase|
              next unless chase["SummitCode"].strip == summit.code # check not chaseof another summit same day
              sc = ExternalChase.new
              sc.asset_type = "summit"
              sc.external_activation_id = aid
              sc.callsign = User.remove_call_suffix(chase["OwnCallsign"].strip)
              sc.band = chase["Band"]
              sc.mode = chase["Mode"]
              acttime = chase["TimeOfDay"].strip
              sc.summit_code = summit.code.strip
              # sc.summit_sota_id=summitId
              sc.date = actdate
              sc.time = Time.parse(actdate + " " + acttime + " UTC")
              dups = ExternalChase.where(sc.attributes.except("summit_sota_id", "id", "updated_at", "created_at", "user_id")).count
              next unless dups.zero?
              puts sc.callsign + ": New!"
              newcount += 1
              sc.save
              user = User.find_by(callsign: sc.callsign)
              user ||= User.create(callsign: sc.callsign, activated: false, password: "dummy", password_confirmation: "dummy", timezone: 1)
              if user
                if Rails.env.production?
                  user.outstanding = true
                  user.save
                  Resque.enqueue(Scorer)
                else
                  user.update_score
                  user.check_awards
                  user.check_completion_awards("district")
                  user.check_completion_awards("region")
                end
              end
            end
          end
        end
        puts "New: " + newcount.to_s
      end
    ensure
      # 3. This block ALWAYS runs, killing the zombie session before the script exits
      if refresh_token
        begin
          # Pull configuration details dynamically from the gem's setup
          token_url = Keycloak.auth_server_url # e.g., "https://your-keycloak-server.com"
          logout_url = token_url.sub("/token", "/logout")
          uri = URI.parse(logout_url)

          # Fire a direct form-urlencoded POST request
          response = Net::HTTP.post_form(uri, {
            client_id: "sotadata",
            client_secret: Rails.application.credentials.sota_secret,
            refresh_token: refresh_token
          })

          # Keycloak returns a 204 No Content response on a successful back-channel logout
          if response.code == "204"
            Rails.logger.debug "SSO session successfully killed via direct API request! No zombies."
          else
            Rails.logger.error("Keycloak rejected the logout request: #{response.code} - #{response.body}")
          end
        rescue => e
          Rails.logger.error("Failed to execute native HTTP logout: #{e.message}")
        end
      end
    end
  end

  def self.update_wwff_activation(asset)
    uri = URI.parse('https://wwff.co/directory')
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    # 2. Initialize the POST Request
    request = Net::HTTP::Post.new(uri.request_uri)
    
    # 3. Set the HTTP Headers
    request['Content-Type'] = 'application/x-www-form-urlencoded'
    request['Pragma'] = 'no-cache'
    request['Cache-Control'] = 'no-cache'
    request['Accept-Encoding'] = 'gzip, deflate' # Replicates the --compressed flag
    
    # 4. Set the Streamlined Form Data
    request.set_form_data({
      'progName' => asset.code[0..3],
      'dxccName' => asset.code[0..3],
      'refID'    => asset.code
    })
     
    begin
      response = http.request(request)

      if response.code == '200'
      # Handle the gzip compression safely
        body = if response['content-encoding'] == 'gzip'
               Zlib::GzipReader.new(StringIO.new(response.body)).read
             else
               response.body
             end
      
          puts "Success! Response body length: #{body.length}"
        # Your HTML content is now in the 'body' variable
      else
        puts "HTTP Request Failed with code: #{response.code}"
      end
    rescue StandardError => e
      puts "An error occurred: #{e.message}"
    end
#    return body

    table=get_table(body, 4)
    row_count = get_row_count(table)
    puts "ROW_COUNT: #{row_count}"
    return if row_count.blank? or row_count<3
    (3..row_count).each do |row_no|
      row = get_row(table,row_no)
      puts row
      act_date = get_col(row,1)
      act_call = get_col(row,2)
      act_qsos = get_col(row,3)
      sa = ExternalActivation.new
      sa.asset_type = "wwff park"
      sa.callsign = User.remove_call_suffix(act_call&.strip)
      if sa.callsign then
        puts "Activator: #{sa.callsign}"
        sa.summit_code = asset.code
        if act_date then sa.date = act_date end
        sa.qso_count = act_qsos
        dups = ExternalActivation.where(sa.attributes.except("id", "updated_at", "created_at", "user_id")).count
        if dups.zero?
          sa.save
          puts sa.to_json
        end
      end
    end
  end
    
  def self.update_pota_activation(asset)
    puts "Park: " + asset.code
    url = "https://api.pota.app/park/activations/" + asset.code.capitalize + "?count=all"
    raw_response = fetch_external_url(url)
    data = JSON.parse(raw_response.blank? ? "[]" : raw_response)
    
    #   data = JSON.parse(open(url, ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE).read)
    if data && data.count.positive?
      puts "Activations: " + data.count.to_s
      newcount = 0
      data.each do |activation|
        sa = ExternalActivation.new
        sa.asset_type = "pota park"
        sa.callsign = User.remove_call_suffix(activation["activeCallsign"].strip)
        sa.summit_code = asset.code.strip
        sa.summit_sota_id = nil
        sa.date = activation["qso_date"].to_date if activation["qso_date"]
        sa.qso_count = activation["totalQSOs"]
        dups = ExternalActivation.where(sa.attributes.except("id", "updated_at", "created_at", "user_id")).count
        next unless dups.zero?
        newcount += 1
        sa.save
        user = User.find_by_callsign_date(sa.callsign, sa.date, true)

        if user
          if Rails.env.production?
            user.outstanding = true
            user.save
            Resque.enqueue(Scorer)
          else
            user.update_score
            user.check_awards
            user.check_completion_awards("district")
            user.check_completion_awards("region")
          end

        end
      end
      puts "New: " + newcount.to_s
    end
  end
end
