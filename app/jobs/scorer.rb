class Scorer
  @queue = :ontheair

  def self.perform(callsign)   
    puts "SCORER: Got called"
    u=User.find_by(callsign: callsign)
    if u then 
      puts "SCORER: Got user "+callsign
      sleep 1
      u.update_score
    end
  end
end
  
