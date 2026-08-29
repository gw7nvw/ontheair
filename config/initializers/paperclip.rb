# config/initializers/paperclip.rb
require 'marcel'

Paperclip.options[:content_type_mappings] = {
  "adi" => "text/plain",
  "adif" => "text/plain"
}


