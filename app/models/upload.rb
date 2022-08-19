class Upload < ActiveRecord::Base
has_attached_file :doc,
:path => ":rails_root/public/system/:attachment/:id/:basename_:style.:extension",
:url => "/system/:attachment/:id/:basename_:style.:extension"


validates_attachment :doc,
    :presence => true
validates_attachment_content_type :doc, :content_type =>["application/text","text/plain","application/octet-stream","text/csv"],
             :message => ', Only ADIF files are permitted '



end
