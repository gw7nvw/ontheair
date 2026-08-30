# frozen_string_literal: true

# typed: true
module SendWwffSpot

  @queue = :ota_scheduled
  def self.perform(spotid)
    # Do anything here, like access models, etc
    puts Time.now.to_s + ' DEBUG: sending wwff spot'
    es=ExternalSpot.find_by(id: spotid)
    if (Time.now-es.time) <180
      puts es.to_json
      topic=Topic.find(SPOT_TOPIC)
      if es and es.time then
        pnp_response = Post.send_to_pnp(false, "[#{es.code}]", es.activatorCallsign, es.frequency, es.mode, es.comments, topic, es.time.strftime('%Y-%m-%d'), es.time.strftime('%H:%M'), 'UTC', es.callsign)
        puts pnp_response.to_json
      end
    end
  end
end
