class Comment < ActiveRecord::Base

def updated_by_name
  user=User.find_by_id(self.updated_by_id)
  if user then user.callsign else "" end
end

def self.for_asset(code)
   comments=Comment.where(code: code)
end
end
