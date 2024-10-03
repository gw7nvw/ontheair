# typed: true
Paperclip.options[:content_type_mappings] = {
  adi: %w(application/octet_stream)
}
require 'paperclip/media_type_spoof_detector'
module Paperclip
  class MediaTypeSpoofDetector
    def spoofed?
      false
    end
  end
end

