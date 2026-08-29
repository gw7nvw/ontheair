# frozen_string_literal: true

# typed: false
class ExternalChase < ActiveRecord::Base
  before_save { before_save_actions }

  def before_save_actions
    remove_call_suffix
    add_user_ids
  end

  def add_user_ids
    # look up callsign1 at contact.time
    user = User.find_by_callsign_date(callsign, date, true)
    self.user_id = user.id if user
  end

  def remove_call_suffix
    self.callsign = User.remove_call_suffix(callsign) if callsign['/']
  end
end
