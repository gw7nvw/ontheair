class UpdateUserids
  @queue = :ota_scheduled

  def self.perform(callsign)   
    puts "UPDATE_USER_IDS: Got called for callsign: "+callsign
    User.reassign_userids_used_by_callsign(callsign)
  end
end
  
