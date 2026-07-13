class SkipBotSessions
  BOT_REGEX = /googlebot|bingbot|yandex|baidu|slurp|duckduckgo|ia_archiver|crawler|spider|bot/i
  CHALLENGE_THRESHOLD = 5
  BLOCK_PERIOD = 1440
  def initialize(app)
    @app = app
  end

  def call(env)
    request = ActionDispatch::Request.new(env)
    user_agent = env['HTTP_USER_AGENT'] || 'Unknown'
    current_path = env['PATH_INFO']
    ip_address = env['REMOTE_ADDR']

    begin
      unless current_path.start_with?('/api') 
        # 1. Fetch the exact tracking record upfront
        ua_record = UserAgent.find_by(user_ip: ip_address, user_agent: user_agent)

        if ua_record
          # 2. AUTO-HEAL: The window expired! Reset their record so a human can try again.
          if  ua_record.updated_at < BLOCK_PERIOD.minutes.ago
            ua_record.update_columns(
              request_count: 0,
              js_count: 0,
              suspicious_access_count: 0,
              confirmed_bot: false,
              confirmed_human: false,
              suspected_bot: false,
              updated_at: Time.now
            )
          end

          unless current_path.start_with?('/signin') || current_path.start_with?('/sessions') || current_path.start_with?('/challenge') or current_path.start_with?('/assets/application.')
          # 3. Check if they are a confirmed bot
            if ua_record.confirmed_human? 
              # Do nothign and stop checks
            elsif ua_record.confirmed_bot?
              # Keep updating the timestamp so active attackers stay locked out indefinitely
              ua_record.touch 
              
              Rails.logger.warn "!!! BLACKLIST BLOCKED: Confirmed bot tried to access #{current_path}"
              return [403, { 'Content-Type' => 'text/plain' }, ["Access Denied.\nYour IP has been blacklisted by this site's anti-bot protection. You can clear this by going to https://ontheair.nz/signin and signing in or by waiting 24 hours before trying again.\n"]]
  
            # 4. Check if they are already a suspect
            elsif ua_record.suspected_bot?
              Rails.logger.warn "!!! BLACKLIST SUSPECT: Known suspected bot returned again #{current_path}"
               # server them challenge page withot wasting time on redirect
               env['PATH_INFO'] = '/challenge'
               current_path  = '/challenge'
    
            # 5. check if they are unknown status, nut have hit our triggers
            elsif ua_record.suspicious_access_count > CHALLENGE_THRESHOLD || (ua_record.access_count>10 && (1.0*ua_record.js_count/ua_record.access_count)<=0.3)
              Rails.logger.info "!!! Hit our trigger thresholds. Mark as suspect and REDIRECT"
                ua_record.update_columns(
                  suspected_bot: true
                )
              # Safety check: Prevent an infinite redirect loop if they are already trying to view the challenge page
              unless current_path.start_with?('/challenge')
                # Escape the path they were trying to access so we can return them later
                escaped_return_to = CGI.escape(current_path)
                
                # Return a 302 Redirect response directly from the middleware, halting the normal flow
                return [302, { 'Location' => "/challenge?referring_url=#{escaped_return_to}" }, []]
              end
            else
              Rails.logger.debug  " Hit none of conditions"
            end
          end
        end
      end
    rescue => e
      Rails.logger.error "Middleware blacklist check failed: #{e.message}"
    end
  
    # B. Pass request down to Rails to execute controllers
    status, headers, response = @app.call(env)

    # D. Track the access count in the database
    begin
      unless current_path.start_with?('/api') 
        # C. check for suspicious activties
        # redirects to login:
        suspicious = (status == 302 && headers['Location']&.include?('/signin') ? 1 : 0)

        # In Rails, AJAX requests pass an HTTP_X_REQUESTED_WITH header, or end in .js
        is_js_request = env['HTTP_X_REQUESTED_WITH'] == 'XMLHttpRequest' || current_path.end_with?('.js')
        request_type  = is_js_request ? :js : :html

        ua_record = UserAgent.track(user_agent, ip_address, suspicious, request_type)
        Rails.logger.info "AGENT: #{ua_record.to_json}"
      end
    rescue => e
      # Prevent a database tracking failure from crashing your entire website
      Rails.logger.error "UserAgentStat tracking failed: #{e.message}"
    end

    # 4. Block the session creation if it's a known bot
    if user_agent.match(BOT_REGEX)
      env['rack.session.options'][:skip] = true
    end

    # 5. Return the response onwards to the browser
    [status, headers, response]
  end
end

