# frozen_string_literal: true

# typed: true
class SendEmails
  @queue = :ota_scheduled

  def self.perform(itemid)
    puts 'SEND EMAILS: Got called for item: ' + itemid.to_s
    Item.send_emails_now(itemid)
  end
end
