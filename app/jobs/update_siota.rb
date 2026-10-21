# frozen_string_literal: true

# typed: true

class UpdateSiota
  @queue = :ontheair

  def self.perform
    Asset.import_siota()
  end
end
