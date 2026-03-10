# frozen_string_literal: true

# typed: true
module UpdateExternalActivations
  @queue = :ota_scheduled

  def self.perform
    puts 'UPDATE_SOTA_ACTIVATIONS: Got called'
    as = AdminSettings.last
    ExternalActivation.import_next_sota
    ExternalActivation.import_next_pota
  end
end
