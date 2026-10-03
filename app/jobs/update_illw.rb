# frozen_string_literal: true

# typed: true
class UpdateIllw
  @queue = :ota_scheduled

  def self.perform()
    Asset.import_illw()
  end
end
