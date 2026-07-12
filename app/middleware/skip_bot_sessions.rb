class SkipBotSessions
  BOT_REGEX = /googlebot|bingbot|yandex|baidu|slurp|duckduckgo|ia_archiver|crawler|spider|bot/i
  CHALLENGE_THRESHOLD = 10
  BLOCK_PERIOD = 60
  def initialize(app)
    @app = app
  end

  def call(env)
    request = ActionDispatch::Request.new(env)
    user_agent = env['HTTP_USER_AGENT'] || 'Unknown'
    current_path = env['PATH_INFO']
    ip_address = env['REMOTE_ADDR']

    # NEW STEP: Cut off confirmed bots instantly before hitting Rails
    unless current_path.start_with?('/signin') || current_path.start_with?('/sessions')
     begin
        # 1. Fetch the exact tracking record upfront
        ua_record = UserAgent.find_by(user_ip: ip_address, user_agent: user_agent)

        if ua_record && ua_record.confirmed_bot?
          # 2. Check if they are still within the active lock window (e.g., 15 minutes)
          if ua_record.updated_at > BLOCK_PERIOD.minutes.ago
            # Keep updating the timestamp so active attackers stay locked out indefinitely
            ua_record.touch 
            
            Rails.logger.warn "!!! BLACKLIST BLOCKED: Confirmed bot tried to access #{current_path}"
            return [403, { 'Content-Type' => 'text/plain' }, ["Access Denied.\n"]]
          else
            # 3. AUTO-HEAL: The window expired! Reset their record so a human can try again.
            ua_record.update_columns(
              request_count: 0,
              suspicious_access_count: 0,
              confirmed_bot: false,
              updated_at: Time.now
            )
          end
        end
      rescue => e
        Rails.logger.error "Middleware blacklist check failed: #{e.message}"
      end
    end

    # 1. Pass request down to Rails to execute controllers
    status, headers, response = @app.call(env)

    # 2. check for suspicious activties
    # redirects to login:
    suspicious = (status == 302 && headers['Location']&.include?('/signin') ? 1 : 0)

    # In Rails, AJAX requests pass an HTTP_X_REQUESTED_WITH header, or end in .js
    is_js_request = env['HTTP_X_REQUESTED_WITH'] == 'XMLHttpRequest' || current_path.end_with?('.js')
    request_type  = is_js_request ? :js : :html

    # 3. Track the access count in the database
    begin
      unless env['PATH_INFO'].match(%r{\A/api(/|\z)}) || current_path.start_with?('/signin') || current_path.start_with?('/sessions')
        ua_record = UserAgent.track(user_agent, ip_address, suspicious, request_type)
        Rails.logger.info "AGENT: #{ua_record.to_json}"
        if !ua_record.confirmed_human and (ua_record.suspected_bot or ua_record.suspicious_access_count > CHALLENGE_THRESHOLD or (ua_record.access_count>10 and (1.0*ua_record.js_count/ua_record.access_count)<=0.3))
          Rails.logger.info "REDIRECT !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
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
        end
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

