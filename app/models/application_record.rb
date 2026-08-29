require 'net/http'
class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class

  def self.fetch_external_url(url_string)
  # 1. Safely handle string inputs by converting them into structured URI objects
  uri = URI.parse(url_string.to_s.strip)

  # 2. Build the request object
  request = Net::HTTP::Get.new(uri)

  # 3. Supply your required User-Agent string to satisfy remote servers
  request['User-Agent'] = USER_AGENT_STRING

  # 4. Open the connection and execute the data transfer securely
  response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == 'https') do |http|
    http.request(request)
  end

  # 5. Handle the response output matrix
  if response.is_a?(Net::HTTPSuccess)
    response.body # Returns the raw unparsed string (JSON, XML, or plain text)
  else
    # Log connection errors gracefully to your Rails environment log files
    Rails.logger.error "External HTTP Fetch Failed: #{response.code} for #{url_string}"
    "" # Return an empty string fallback to prevent downstream split/parse operations from crashing
  end
rescue StandardError => e
  # Intercept network dropouts, DNS failures, or timeout exceptions cleanly
  Rails.logger.error "External HTTP Network Error: #{e.message} for #{url_string}"
  ""
end

end
