class SendNotifications
  @queue = :notifications

  def self.perform(spot_id, is_new_record)
    spot = ConsolidatedSpot.find_by(id: spot_id)
    return unless spot

    # 1. CONCURRENCY LOCK: Prevent duplicate processing for the exact same spot
    lock_key = "lock:spot_notification:#{spot_id}"

    # Set a 5-minute expiring lock in Redis. If it's already locked, exit.
    # (Resque.redis handles the underlying Redis connection)
    return unless Resque.redis.set(lock_key, "true", { ex: 300, nx: true })


    begin
      # 2. RUN HIGH-SPEED REVERSE MATCH
      potential_matches = UserNotificationLink.matching_spot(spot)
      return if potential_matches.empty?

      # 3. HEAVY CPU OPERATION: Generate map/payload EXACTLY ONCE
      image_base64 = MapImageService.generate_matrix(spot.code) # Matrix 9 tiles into 1 jpeg
      message_url  = spot.url
      last_comment = spot.comments.last
      asset_names = spot.asset_names
      summary = spot.summary
      email_payload = nil # Lazily rendered once if at least one email subscriber matches

      # 4. ITERATE & DISPATCH HTTP CALLS SEQUENTIALLY
      # Because the image is pre-compiled, this loop executes extremely fast.
      potential_matches.each do |link|
        user = link.user
        next if spot.code==[ "ZL3/HSL-001" ] and user.id!=4  # Test site only for ZL4NVW!
        next unless user

        # Deduplicate updates using your one-hour ledger table
        begin
          SentNotification.create!(user_id: user.id, notification_type: link.notification_type, consolidated_spot_id: spot.id)
        rescue ActiveRecord::RecordNotUnique
          next # Already notified within the hour
        end

        Resque.logger.info("SEND_NOTIFICTAION: #{user.callsign} #{summary}")
        puts "SEND_NOTIFICTAION: #{user.callsign} #{summary}"
        case link.notification_type
        when NOTIFICATION_PUSHOVER
          PushoverService.send_alert(user, summary, message_url, last_comment, image_base64, link.priority)
        when NOTIFICATION_EMAIL
          email_payload ||= EmailService.prepare_payload(summary, asset_names, message_url, last_comment)
          EmailService.send_alert(user, email_payload, image_base64)
        else
          Resque.logger.error "Invalid Notification type: #{link.notification_type} for user_id: #{link.user_id}"
        end
      end

      # 5. Clean up old ledger data safely at the end of the run
      SentNotification.where("created_at < ?", 1.hour.ago).delete_all

    ensure
      # ALWAYS release the concurrency lock when finished or if an error occurs
      Resque.redis.del(lock_key)
    end
  end
end
