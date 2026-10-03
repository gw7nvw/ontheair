# frozen_string_literal: true

# typed: true
class UpdatePota
  @queue = :ota_scheduled

  def self.perform()
    Asset.import_vk_pota(true, false, true, nil)
    #Asset.import_pota('ZL')
  end
end
