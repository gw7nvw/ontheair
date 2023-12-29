class SotaChase < ActiveRecord::Base

before_save { self.before_save_actions }

def before_save_actions
  self.remove_suffix
  self.add_user_ids
end

def add_user_ids
    #look up callsign1 at contact.time
    user=User.find_by_callsign_date(self.callsign, self.date, true)
    if user then self.user_id=user.id end
end

def remove_suffix
  if self.callsign['/'] then self.callsign=Log.remove_suffix(self.callsign) end
end

end
