# typed: true
module GetSpots

  @queue = :ota_scheduled
  def self.perform()
    # Do anything here, like access models, etc
    puts Time.now.to_s+" DEBUG: checking for new spots"
    ExternalSpot.fetch
  end
end
