# typed: false
# Load the Rails application.
require File.expand_path('../application', __FILE__)

# Initialize the Rails application.
Hota::Application.initialize!

Mime::Type.register "text/xml", :gpx

Rails.logger = Logger.new(STDOUT)
#Rails.logger = Log4r::Logger.new("Application Log")

#Rails.logger = ActiveSupport::Logger.new('log/debug3.log')
