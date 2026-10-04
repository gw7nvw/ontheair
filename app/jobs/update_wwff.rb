# frozen_string_literal: true

# typed: true
class UpdateWwff
  @queue = :ota_scheduled

  def self.perform()
    Asset.import_wwff('VK',true, false, true)
    Asset.import_wwff('ZL',true, false, true)
  end
end
