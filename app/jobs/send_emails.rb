# frozen_string_literal: true

# typed: true
class SendEmails
  @queue = :ota_scheduled

  def self.perform(itemid)
    Resque.logger.info 'SEND EMAILS: Got called for item: ' + itemid.to_s
      if ENV['RAILS_ENV'] != 'production'
        Resque.logger.info "EMAIL: not sending in #{ENV['RAILS_ENV']} environment - #{itemid}"
      else
        Item.send_emails_now(itemid)
      end
  end
end
