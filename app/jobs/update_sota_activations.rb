# frozen_string_literal: true

# typed: true
class UpdateExternalActivations
  @queue = :ota_scheduled

  def self.perform
    puts 'UPDATE_SOTA_ACTIVATIONS: Got called'
    as = AdminSettings.last
    if !as.last_sota_activation_update_at || ((as.last_sota_activation_update_at + 30.days) <= Time.now)
      as.last_sota_activation_update_at = Time.now
      as.save
      ExternalActivation.import_sota
      ExternalActivation.import_pota
    end
  end
end
