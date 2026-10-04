# frozen_string_literal: true

# typed: true
class UpdateNzgdb
  @queue = :ota_scheduled

  def self.perform()
    Nzgdb.update
    #Now update lakes
    #Now update islands
  end
end
