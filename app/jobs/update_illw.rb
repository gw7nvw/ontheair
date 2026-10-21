# frozen_string_literal: true

# typed: true

class UpdateIllw
  @queue = :ontheair

  def self.perform
    Asset.import_illw()
  end
end
