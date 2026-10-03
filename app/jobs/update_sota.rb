# frozen_string_literal: true

# typed: true
class UpdateSota
  @queue = :ota_scheduled

  def self.perform()
    Asset.import_sota('VK')
    Asset.import_sota('ZL')
  end
end
