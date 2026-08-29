# frozen_string_literal: true

# typed: true
class Upload < ActiveRecord::Base
  has_attached_file :doc,
                    path: ':rails_root/public/system/:attachment/:id/:basename_:style.:extension',
                    url: '/system/:attachment/:id/:basename_:style.:extension'

  validates_attachment :doc,
                       presence: true
  validates_attachment_content_type :doc, 
    content_type: ['application/text', 'text/plain', 'application/octet-stream', 'text/csv'],
    message: 'Only ADIF files are permitted'
#  Add this explicit line right below it to skip the Marcel/MimeMagic spoof mismatch error
  do_not_validate_attachment_file_type :doc

  attr_accessor :doc_do_not_lookup
  attr_accessor :doc_unreliable_chaser_loc
end
