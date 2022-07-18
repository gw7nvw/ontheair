class Scorer
  @queue = :ontheair

  def self.perform()   
    puts "SCORER: Got called"
    sleep 1
    us=User.where(outstanding: true)
    us.each do |u|
      puts "SCORER: Got user "+u.callsign
      u.outstanding=false
      u.save
      u.update_score
      u.check_awards
      u.check_district_awards
    end
  end
end
  
