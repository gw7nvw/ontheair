# frozen_string_literal: true

# typed: true

class UpdatePota
  @queue = :ontheair

  def self.perform
    Asset.import_pota('VK', true, false, true, nil)
    #Asset.import_pota('ZL', true, false, true, nil)
    # Asset.import_pota('ZL')
  end
end
