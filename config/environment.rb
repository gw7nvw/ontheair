# Load the Rails application.
require File.expand_path('../application', __FILE__)

# Initialize the Rails application.
Hota::Application.initialize!

Mime::Type.register "text/xml", :gpx

