#!/usr/bin/env ruby
# frozen_string_literal: true

# typed: true
require 'resque'
require 'redis'
require 'mail'

class EmailReceive
  @queue = :ontheair
  SPOT_TOPIC_ID = 35
  ALERT_TOPIC_ID = 1
  TEST_SPOT_TOPIC_ID = 43
  TEST_ALERT_TOPIC_ID = 44

    # Resque's worker execution method (called by the background worker container)
  def self.perform(from, to, subject, body, file)
    # This is where your downstream processing logic handles the message variables.
    # (Leaving this definition intact so Resque knows how to handle the class queue!)
    Rails.logger.info "Processing email from #{from} inside environment: #{Rails.env}" if defined?(Rails)
    
    via = ''
    posttype = nil
    if to[0..3].casecmp('SPOT').zero?
      Resque.logger.debug 'DEBUG: SPOT'
      posttype = 'spot'
    end
    if to[0..4].casecmp('ALERT').zero?
      Resque.logger.debug 'DEBUG: ALERT'
      posttype = 'alert'
    end
    if to[0..6].casecmp('ZL-SOTA').zero? or to[0..5].casecmp('ZLSOTA').zero?
      Resque.logger.debug 'DEBUG: ZL-SOTA'
      posttype = 'zlsota'
    end
    if to[0..3].casecmp('LOGS').zero?
      Resque.logger.debug 'DEBUG: LOGS'
      posttype = 'logs'
    end
    # params = {
    #   body: body,
    #   to: to,
    #   subject: subject,
    #   from: from
    # }
    Resque.logger.debug 'DEBUG body: ' + body
    Resque.logger.debug 'DEBUG subject: ' + (subject || '')
    Resque.logger.debug 'DEBUG from: ' + (from || '')
    Resque.logger.debug 'DEBUG to: ' + (to || '')

    # forward mail to zl-sota
    if posttype == 'zlsota'
      UserMailer.zlsota_mail(body.gsub(/https.*$/, '{link removed}'), subject).deliver_now
    # upload a log
    elsif posttype == 'logs'
      username = nil
      pin = nil
      if subject['ZLOTA']
        Resque.logger.debug 'DEBUG: Valid subject'
        creds = subject.split('ZLOTA')
        if creds && creds.count.positive?
          username = creds[1].split(':')[1]
          pin = creds[1].split(':')[2]
          Resque.logger.debug "DEBUG: username: #{username}"
          Resque.logger.debug "DEBUG: pin: #{pin}" 
        end
      end
      # if username and pin and api_authenticate(username, pin) then
      user = User.find_by(callsign: username, pin: pin)
      if user 
        Resque.logger.debug 'DEBUG: Authenticated'
        res = { success: true, message: '' }
        filetype='adif'
        logs = Log.import(filetype, user, file, user)
        Resque.logger.debug 'DEBUG: Imported'
        if logs[:success] == false
          res = { success: false, message: logs[:errors].join(', ') }
        end
        if (logs[:success] == true) && logs[:errors] && logs[:errors].count.positive?
          res = { success: true, message: 'Warnings: ' + logs[:errors].join(', ') }
        end
      else
        Resque.logger.error "DEBUG: Authenticaton failed '#{username}', '#{pin}'"
        res = { success: false, message: 'Login failed using supplied credentials' }
      end
      Resque.logger.debug 'Result: ' + res[:message]
      if (res[:success] == false) || (res[:message] != '')
        # reply with error (swapping to and from)
        UserMailer.free_form_mail(from, to, 'Re: ' + subject, res[:message]).deliver
      end

    else
      # check for correct format
      if body['inr.ch'] || body['js8.gate'] || body['INR.CH'] || body['JS8.GATE'] || body['/eom'] || body['/EOM']
        if body['inr.ch']
          via = 'InReach'
          splt = 'inr.ch'
        elsif body['INR.CH']
          via = 'InReach'
          splt = 'INR.CH'
        elsif body['js8.gate']
          via = 'JS8Gate'
          splt = 'js8.gate'
        elsif body['JS8.GATE']
          via = 'JS8Gate'
          splt = 'JS8.GATE'
        elsif body['/eom']
          via = 'Email'
          splt = '/eom'
        else
          via = 'Email'
          splt = '/EOM'
        end

        if subject && subject['Predefined 1-way message from SOTAmat user']
          via = 'SOTAmat'
          validated_user = subject.split.last
        end
        Resque.logger.debug 'DEBUG: via ' + via

        msg = body.split(splt)[0]
        msg = msg.split('/bom')[1] if msg['/bom']
        msg = msg.split('/BOM')[1] if msg['/BOM']

        msgs = msg.split
        sub_callsign = msgs[0].upcase
        passkey = msgs[1].upcase
        user = User.find_by(callsign: sub_callsign)
        unless user
          Resque.logger.debug 'Unknown callsign: ' + sub_callsign
          return(false)
        end

        msgs=msgs[2..-1]
        # should check a password here
        if validated_user
          if validated_user.upcase != sub_callsign
            Resque.logger.error "Account name '" + validated_user.upcase + "' does not match callsign '" + sub_callsign + "'"
            return(false)
          end
        elsif !user.pin || (passkey[0..3] != user.pin[0..3])
          Resque.logger.error 'PIN does not match'
          return(false)
        end
      elsif subject && subject['You have a new SMS']
        via = 'SMS'
        Resque.logger.debug 'DEBUG SMS'
        msg = 'SMS ' + body
        Resque.logger.debug 'DEBUG body: ' + body
        #remove timestamp
        body=body.gsub(/\((0[1-9]|[12][0-9]|3[01])\/(0[1-9]|1[0,1,2])\/\d{2} \d{2}:\d{2} [AP]M\)/,'')
        Resque.logger.debug 'DEBUG body: ' + body
        lines = body.split(/\r?\n/)
        Resque.logger.debug "DEBUG lines "+lines.to_json
        msgs = lines[1].split
        msgs = msgs[1..-1] if msgs
        Resque.logger.debug "DEBUG msgs "+msgs.to_json
        if msgs[0].upcase=='ALERT' then
          posttype='alert'
          msgs=msgs[1..-1]
        elsif msgs[0].upcase=='SPOT' then
          posttype='spot'
          msgs=msgs[1..-1]
        else
          posttype='spot'
        end
    
        # passkey = nil
        acctnumber = lines[0].split[2]
        acctnumber = acctnumber.strip.delete(' ')
        Resque.logger.debug 'DEBUG subject: ' + subject
        Resque.logger.debug 'DEBUG from number: ' + acctnumber
        user = User.find_by(acctnumber: acctnumber)
        Resque.logger.error "ERROR: account not found for " + acctnumber if !user
      end

      if msgs then
        callsign = msgs[0].upcase
        callsign = sub_callsign if callsign == '!'
        asset_code = msgs[1].upcase
        if asset_code.include?('/') || asset_code.include?('-')
          Resque.logger.debug 'DEBUG: asset code appears to be complete'
        else
          Resque.logger.debug 'DEBUG: asset code looks like SOTA-spot format'
          asset_suffix = msgs[2]
          unless asset_suffix.include?('-')
            Resque.logger.debug "DEBUG: asset suffix with no '-'"
            asset_suffix = asset_suffix.gsub(/([a-zA-Z])([0-9])/, '\1-\2')
          end
          asset_code = asset_code + '/' + asset_suffix
          msgs=[msgs[0],asset_code]+msgs[3..-1]
          msgs.delete_at(msgs.length - 1)
          Resque.logger.debug 'DEBUG: concatenated asset code = ' + asset_code
        end
        freq = msgs[2]
        mode = msgs[3].upcase
        if posttype == 'spot'
          comments = msgs[4..-1].join(' ')
          al_date = Time.now.in_time_zone('UTC').strftime('%Y-%m-%d')
          al_time = Time.now.in_time_zone('UTC').strftime('%H:%M')
        else
          al_date = msgs[4]
          al_time = msgs[5]
          comments = msgs[6..-1].join(' ')
        end
  
        @post = Post.new
        debug = comments.upcase['DEBUG'] ? true : false
  
        # check asset
        assets = Asset.assets_from_code(asset_code)
        # if !assets or assets.count==0 or assets.first[:code]==nil then puts "Asset not known:"+asset_code ;return(false) end
        if !assets || assets.count.zero? || assets.first[:code].nil?
          Resque.logger.debug 'Asset not known:' + asset_code + ' ... trying to continue'
          a_code = ''
          a_name = 'Unrecognised location: ' + asset_code
          a_ext = false
        else
          a_code = assets.first[:code]
          a_name = assets.first[:name]
          a_ext = assets.first[:external]
        end
  
        asset_type = Asset.get_asset_type_from_code(a_code)
        if comments.downcase.include?("/dnl")
          comments=comments.gsub("/dnl","").gsub("/DNL","")
          @post.do_not_lookup = true
        end
  
        if user
  
          # fill in details
          @post.mode = mode.upcase
          @post.callsign = callsign
          @post.freq = freq
          @post.asset_codes = a_code != '' ? [a_code] : []
          @post.created_by_id = user.id
          @post.updated_by_id = user.id
          @post.description = comments + ' (via ' + via + ')'

          @post.referenced_time = (al_date + ' ' + al_time + ' UTC').to_time
          @post.referenced_date = (al_date + ' 00:00:00 UTC').to_time
          @post.updated_at = Time.now
          Resque.logger.debug 'DEBUG: assets - ' + a_name
          if posttype == 'spot'
            topic_id = if debug
                         TEST_SPOT_TOPIC_ID
                       else
                         SPOT_TOPIC_ID
                       end
            @post.title = 'SPOT: ' + callsign + ' spotted portable at ' + a_name + ' [' + a_code + '] on ' + freq + '/' + mode + ' at ' + Time.now.in_time_zone('Pacific/Auckland').strftime('%Y-%m-%d %H:%M') + 'NZ'
          else
            topic_id = if debug
                         TEST_ALERT_TOPIC_ID
                       else
                         ALERT_TOPIC_ID
                       end
            @post.title = 'ALERT: ' + callsign + ' going portable to ' + a_name + ' [' + a_code + '] on ' + freq + '/' + mode + ' at ' + al_date + ' ' + al_time + ' UTC'
          end
          res = @post.save
          if res
            if a_ext == false
              @post.add_map_image
              res = @post.save
            end
            item = Item.new
            item.topic_id = topic_id
            item.item_type = 'post'
            item.item_id = @post.id
            item.save
            item.send_emails
          end
          @topic = Topic.find_by_id(topic_id)
          if defined?(Rails) && Rails.env.production?
            @post.send_to_all(debug, user.callsign, @post.callsign,  @post.asset_codes,  @post.freq, @post.mode, @post.description, @topic, al_date, al_time, 'UTC')
          else
            Resque.logger.debug "SKIPPING: send_to_all in non-production environment"
          end
        end
      else
        Resque.logger.error "DEBUG: Invalid spot / alert message"
        Resque.logger.error "====START===="
        Resque.logger.error body
        Resque.logger.error "=====END====="
      end
    end
  end

  def self.api_authenticate(username, pin)
    Resque.logger.debug 'DEBUG: authenticating'
    valid = false
    if username && pin
      Resque.logger.debug 'DEBUG: comparing username'
      user = User.find_by(callsign: username.upcase)
      Resque.logger.debug 'DEBUG: comparing pin'
      if user && user.pin.casecmp(pin).zero?
        Resque.logger.debug 'DEBUG: valid pin'
        valid = true
      end
    end
    valid
  end

  def initialize(content)
    mail    = Mail.read_from_string(content)
    from    = mail.from&.first
    to      = mail.to&.first
    subject = mail.subject
    file = nil
    if mail.multipart?
      part = mail.parts.find { |p| p.content_type =~ /text\/plain/ } rescue nil
      attachment = mail.parts.find { |p| p.content_type =~ /application\/octet-stream/ } rescue nil

      file = attachment.decoded if attachment
      message = part.body.decoded if part
    else
      message = mail.decoded
    end
    Resque.logger.debug "MESSAGE: #{message}"
    if message
      # Clean, Dynamic Environment Dispatch
      if defined?(Rails) && !Rails.env.production?
        # In Test or Development modes, execute inline instantly for simple testing!
        self.class.perform(from, to, subject, message, file)
      else
        # In Production (or outside Rails completely via Postfix), push to Redis
        Resque.enqueue(EmailReceive, from, to, subject, message, file)
      end
    end
  end
end

# This line intercepts the execution block ONLY when Postfix drives the file via command line
if __FILE__ == $0
  EmailReceive.new(STDIN.read)
end
