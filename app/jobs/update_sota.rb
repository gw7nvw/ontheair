# frozen_string_literal: true

# typed: true

class UpdateSota
  @queue = :ontheair

  def self.perform
    Asset.import_sota("VK")
    Asset.import_sota("ZL")
  end
end
