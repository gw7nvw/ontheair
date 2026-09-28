# frozen_string_literal: true

# typed: true
class SendEmails
  @queue = :ota_scheduled

  def self.perform(itemid)
    puts 'SEND EMAILS: Got called for item: ' + itemid.to_s
      if PRODENV and PRODENV=='UAT' then
        logger.info "EMAIL: not sending in UAT environment - #{itemid}"
      else
        Item.send_emails_now(itemid)
      end
  end
end
