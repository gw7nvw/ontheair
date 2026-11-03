# frozen_string_literal: true

# typed: true

class UpdatePota
  @queue = :ontheair

  def self.perform
    Asset.import_pota("AU", true, false, true, nil)
    # Asset.import_pota('NZ', true, false, true, nil)
    # Asset.import_pota('ZL')
  end
end
