# frozen_string_literal: true

# typed: true

class SendEmails
  @queue = :ota_scheduled

  def self.perform(itemid)
    # 1. CONCURRENCY LOCK: Prevent duplicate processing for the exact same spot
    lock_key = "lock:send_email:#{itemid}"

    # Set a 5-minute expiring lock in Redis. If it's already locked, exit.
    # (Resque.redis handles the underlying Redis connection)
    return unless Resque.redis.set(lock_key, "true", { ex: 300, nx: true })

    begin
      Resque.logger.info "SEND EMAILS: Got called for item: " + itemid.to_s
      if ENV["RAILS_ENV"] != "production"
        Resque.logger.info "EMAIL: not sending in #{ENV['RAILS_ENV']} environment - #{itemid}"
      else
        Item.send_emails_now(itemid)
      end
    ensure
      # ALWAYS release the concurrency lock when finished or if an error occurs
      Resque.redis.del(lock_key)
    end
  end
end
