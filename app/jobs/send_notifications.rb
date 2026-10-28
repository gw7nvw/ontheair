class SendNotifications
  @queue = :notifications

  def self.perform(spot_id, is_new_record)
    spot = ConsolidatedSpot.find_by(id: spot_id)
    return unless spot

    # 1. CONCURRENCY LOCK: Prevent duplicate processing for the exact same spot
    lock_key = "lock:spot_notification:#{spot_id}"

    # Set a 5-minute expiring lock in Redis. If it's already locked, exit.
    # (Resque.redis handles the underlying Redis connection)
    return unless Resque.redis.set(lock_key, "true", {ex: 300, nx: true})


    begin
      # 2. RUN HIGH-SPEED REVERSE MATCH
      potential_matches = UserNotificationLink.matching_spot(spot)
      return if potential_matches.empty?

      # 3. HEAVY CPU OPERATION: Generate map/payload EXACTLY ONCE
      image_base64 = MapImageService.generate_matrix(spot.code) # Matrix 9 tiles into 1 jpeg
      message_url  = spot.url

      # 4. ITERATE & DISPATCH HTTP CALLS SEQUENTIALLY
      # Because the image is pre-compiled, this loop executes extremely fast.
      potential_matches.each do |link|
        user = link.user
        next unless user

        # Deduplicate updates using your one-hour ledger table
        begin
          SentNotification.create!(user_id: user.id, consolidated_spot_id: spot.id)
        rescue ActiveRecord::RecordNotUnique
          next # Already notified within the hour
        end

        Resque.logger.info("SEND_NOTIFICTAION: #{user.callsign} #{spot.summary}")

        # Ship individual payload using user-isolated tokens
        PushoverService.send_alert( user, spot.summary, message_url, spot.comments.last, image_base64, link.priority )
      end

      # 5. Clean up old ledger data safely at the end of the run
      SentNotification.where('created_at < ?', 1.hour.ago).delete_all

    ensure
      # ALWAYS release the concurrency lock when finished or if an error occurs
      Resque.redis.del(lock_key)
    end
  end
end
