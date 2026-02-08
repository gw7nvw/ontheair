# frozen_string_literal: true

# typed: false
class InvalidReplyUser < StandardError; end

class EmailReceive
  @queue = :ontheair
  SPOT_TOPIC_ID = 35
  ALERT_TOPIC_ID = 1
  TEST_SPOT_TOPIC_ID = 43
  TEST_ALERT_TOPIC_ID = 44

  def self.perform(from, to, subject, body, attachment)
    via = ''
    posttype = nil
    if to[0..3].casecmp('SPOT').zero?
      puts 'DEBUG: SPOT'
      posttype = 'spot'
    end
    if to[0..4].casecmp('ALERT').zero?
      puts 'DEBUG: ALERT'
      posttype = 'alert'
    end
    if to[0..6].casecmp('ZL-SOTA').zero? or to[0..5].casecmp('ZLSOTA').zero?
      puts 'DEBUG: ZL-SOTA'
      posttype = 'zlsota'
    end
    if to[0..3].casecmp('LOGS').zero?
      puts 'DEBUG: LOGS'
      posttype = 'logs'
    end
    # params = {
    #   body: body,
    #   to: to,
    #   subject: subject,
    #   from: from
    # }
    puts 'DEBUG body: ' + body
    puts 'DEBUG subject: ' + (subject || '')
    puts 'DEBUG from: ' + (from || '')
    puts 'DEBUG to: ' + (to || '')

    # forward mail to zl-sota
    if posttype == 'zlsota'
      UserMailer.zlsota_mail(body.gsub(/https.*$/, '{link removed}'), subject).deliver
    # upload a log
    elsif posttype == 'logs'
      username = nil
      pin = nil
      if subject['ZLOTA']
        puts 'DEBUG: Valid subject'
        creds = subject.split('ZLOTA')
        if creds && creds.count.positive?
          username = creds[1].split(':')[1]
          pin = creds[1].split(':')[2]
          puts 'DEBUG: username: ' + username
          puts 'DEBUG: pin: ' + pin
        end
      end
      # if username and pin and api_authenticate(username, pin) then
      if api_authenticate(username, pin)
        puts 'DEBUG: Authenticated'
        res = { success: true, message: '' }
        logs = Log.import(attachment, nil)
        puts 'DEBUG: Imported'
        if logs[:success] == false
          res = { success: false, message: logs[:errors].join(', ') }
        end
        if (logs[:success] == true) && logs[:errors] && logs[:errors].count.positive?
          res = { success: true, message: 'Warnings: ' + logs[:errors].join(', ') }
        end
      else
        puts "DEBUG: Authenticaton failed '#{username}', '#{pin}'"
        res = { success: false, message: 'Login failed using supplied credentials' }
      end
      puts 'Result: ' + res[:message]
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
          validated_user = subject.split(' ').last
        end
        puts 'DEBUG: via ' + via

        msg = body.split(splt)[0]
        msg = msg.split('/bom')[1] if msg['/bom']
        msg = msg.split('/BOM')[1] if msg['/BOM']

        msgs = msg.split(' ')
        sub_callsign = msgs[0].upcase
        passkey = msgs[1].upcase
        user = User.find_by(callsign: sub_callsign)
        unless user
          puts 'Unknown callsign: ' + sub_callsign
          return(false)
        end

        # should check a password here
        if validated_user
          if validated_user.upcase != sub_callsign
            puts "Account name '" + validated_user.upcase + "' does not match callsign '" + sub_callsign + "'"
            return(false)
          end
        elsif !user.pin || (passkey[0..3] != user.pin[0..3])
          puts 'PIN does not match'
          return(false)
        end
      elsif subject && subject['You have a new SMS']
        via = 'SMS'
        puts 'DEBUG SMS'
        msg = 'SMS ' + body
        puts 'DEBUG body: ' + body
        lines = body.split(/\r?\n/)
        puts "DEBUG lines "+lines.to_json
        msgs = lines[1].split(' ')
        msgs = msgs[1..-1] if msgs
        puts "DEBUG msgs "+msgs.to_json
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
        acctnumber = lines[0].split(' ')[2]
        acctnumber = acctnumber.strip.delete(' ')
        puts 'DEBUG subject: ' + subject
        puts 'DEBUG from number: ' + acctnumber
        user = User.find_by(acctnumber: acctnumber)
        puts "ERROR: account not found for " + acctnumber if !user
      end

      if msgs then
        callsign = msgs[0].upcase
        callsign = sub_callsign if callsign == '!'
        asset_code = msgs[1].upcase
        if asset_code.include?('/') || asset_code.include?('-')
          puts 'DEBUG: asset code appears to be complete'
        else
          puts 'DEBUG: asset code looks like SOTA-spot format'
          asset_suffix = msgs[2]
          unless asset_suffix.include?('-')
            puts "DEBUG: asset suffix with no '-'"
            asset_suffix = asset_suffix.gsub(/([a-zA-Z])([0-9])/, '\1-\2')
          end
          asset_code = asset_code + '/' + asset_suffix
          (4..msgs.length - 2).each do |cnt|
            msgs[cnt] = msgs[cnt + 1]
          end
          msgs.delete_at(msgs.length - 1)
          puts 'DEBUG: concatenated asset code = ' + asset_code
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
          puts 'Asset not known:' + asset_code + ' ... trying to continue'
          a_code = ''
          a_name = 'Unrecognised location: ' + asset_code
          a_ext = false
        else
          a_code = assets.first[:code]
          a_name = assets.first[:name]
          a_ext = assets.first[:external]
        end
  
        asset_type = Asset.get_asset_type_from_code(a_code)
        if (posttype == 'spot') && ((asset_type == 'SOTA') || (asset_type == 'summit'))
          puts 'DEBUG: sending to SOTA'
          result = @post.send_to_sota(debug, acctnumber, callsign, a_code, freq, mode, comments + ' (ontheair.nz)')
          puts 'DEBUG: ' + result.to_s
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
          puts 'DEBUG: assets - ' + a_name
          if posttype == 'spot'
            topic_id = if debug
                         TEST_SPOT_TOPIC_ID
                       else
                         SPOT_TOPIC_ID
                       end
            @post.title = 'SPOT: ' + callsign + ' spotted portable at ' + a_name + '[' + a_code + '] on ' + freq + '/' + mode + ' at ' + Time.now.in_time_zone('Pacific/Auckland').strftime('%Y-%m-%d %H:%M') + 'NZ'
          else
            topic_id = if debug
                         TEST_ALERT_TOPIC_ID
                       else
                         ALERT_TOPIC_ID
                       end
            @post.title = 'ALERT: ' + callsign + ' going portable to ' + a_name + '[' + a_code + '] on ' + freq + '/' + mode + ' at ' + al_date + ' ' + al_time + ' UTC'
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
          @post.asset_codes.each do |ac|
            asset_type = Asset.get_asset_type_from_code(ac)
            if (posttype == 'spot') && (asset_type == 'pota park') || (asset_type == 'POTA')
              puts 'DEBUG: sending to POTA'
              success = @post.send_to_pota(debug, user.callsign, @post.callsign, ac, @post.freq, @post.mode, @post.description)
              puts 'DEBUG: success = ' + success.to_s
            elsif !((asset_type == 'SOTA') || (asset_type == 'summit'))
              puts 'DEBUG: sending to PnP'
              res = Post.send_to_pnp(debug, ac, @post.callsign, @post.freq, @post.mode, @post.description, @topic, al_date, al_time, 'UTC', user.callsign)
              puts 'DEBUG: success = ' + res.to_s
            end
          end
        end
      else
        puts "DEBUG: Invalid spot / alert message"
        puts "====START===="
        puts body
        puts "=====END====="
      end
    end
  end

  def self.api_authenticate(username, pin)
    puts 'DEBUG: authenticating'
    valid = false
    if username && pin
      puts 'DEBUG: comparing username'
      user = User.find_by(callsign: username.upcase)
      puts 'DEBUG: comparing pin'
      if user && user.pin.casecmp(pin).zero?
        puts 'DEBUG: valid pin'
        valid = true

        # authenticate via PnP
        # if not a local user, or is a local user and have allowed PnP logins
        # if !user or (user and user.allow_pnp_login==true) then
      elsif user && (user.allow_pnp_login == true)
        params = { 'actClass' => 'WWFF', 'actCallsign' => 'test', 'actSite' => 'test', 'mode' => 'SSB', 'freq' => '7.095', 'comments' => 'Test', 'userID' => username, 'APIKey' => pin }
        res = send_spot_to_pnp(params, '/DEBUG')
        if res.body =~ 'Success'
          valid = true
          puts 'AUTH: SUCCESS authenticated via PnP'
        else
          puts 'AUTH: FAILED authentication via PnP'
        end
      end
    end
    valid
  end
end
