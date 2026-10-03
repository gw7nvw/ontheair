# frozen_string_literal: true

# typed: true
class UpdateSiota
  @queue = :ota_scheduled

  def self.perform()
    Asset.import_siota()
  end
end
