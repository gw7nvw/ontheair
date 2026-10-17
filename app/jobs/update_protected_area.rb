# frozen_string_literal: true

# typed: true

class UpdateProtectedArea
  @queue = :ota_scheduled

  def self.perform
    ProtectedArea.run_full_update
  end
end
