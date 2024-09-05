class ExternalChase < ActiveRecord::Base

before_save { self.before_save_actions }

def before_save_actions
  self.remove_call_suffix
  self.add_user_ids
end

def add_user_ids
    #look up callsign1 at contact.time
    user=User.find_by_callsign_date(self.callsign, self.date, true)
    if user then self.user_id=user.id end
end

def remove_call_suffix
  if self.callsign['/'] then self.callsign=User.remove_call_suffix(self.callsign) end
end

end
