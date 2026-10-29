class PushoverService
  PUSHOVER_URL = "https://api.pushover.net/1/messages.json".freeze

  # Make it a class method so it can be called seamlessly without instantiation
  def self.send_alert(user, notification, url, comments, image_base64, priority)
    if user.push_app_token.blank? or user.push_user_token.blank?
      Resque.logger.error "User has no pushover credentials: #{user.callsign} (#{user.id})"
      return
    end
    if comments and user.push_include_comments then notification += ": "+comments end


    uri = URI.parse(PUSHOVER_URL)
    req = Net::HTTP::Post.new(uri.request_uri)
    
    payload = {
      token:    user.push_app_token,
      user:     user.push_user_token,
      priority: priority,
      message:  notification.to_s.scrub.strip,
    }

    unless ENV["RAILS_ENV"] == "production"
      Resque.logger.info "NOTIFICATION: not sending in #{ENV['RAILS_ENV']} environment - #{payload.to_json}"
      puts "NOTIFICATION: not sending in #{ENV['RAILS_ENV']} environment - #{payload.to_json}"
      return
    end

    # Add optional fields only if they are present
    payload[:url] = url if url.present?
    
    if image_base64.present? and user.push_include_map!=false
      payload[:attachment_base64] = image_base64
      payload[:attachment_type]   = "image/jpeg"
    end

    req.set_form_data(payload)

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.open_timeout = 3
    http.read_timeout = 5
    
    response = http.request(req)
    
    # Optional: Parse response to log bad credentials
    if response.code == "400"
      puts "ERROR: Pushover API 400 Error: #{response.body}"
      Resque.logger.error "Pushover API 400 Error: #{response.body}"
      Rails.logger.error "Pushover API 400 Error: #{response.body}"
    end
    
    response
#  rescue Timeout::Error, Errno::ECONNREFUSED => e
#    Rails.logger.error "Pushover network connection failed: #{e.message}"
#    nil
  end
end
