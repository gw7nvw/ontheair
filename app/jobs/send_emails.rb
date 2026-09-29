# frozen_string_literal: true

# typed: true
class SendEmails
  @queue = :ota_scheduled

  def self.perform(itemid)
    Resque.logger.info 'SEND EMAILS: Got called for item: ' + itemid.to_s
    Resque.logger.info "SEND PRODENV: #{PRODENV}"
      if PRODENV and (PRODENV=='UAT' or PRODENV=='SECONDARY') then
        Resque.logger.info "EMAIL: not sending in UAT environment - #{itemid}"
      else
        Item.send_emails_now(itemid)
      end
  end
end
