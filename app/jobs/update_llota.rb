# frozen_string_literal: true

# typed: true
class UpdateLlota
  @queue = :ota_scheduled

  def self.perform()
    Asset.import_llota('AU',true, false, true)
    #    Asset.import_llota('NZ',true, false, true)  #Does not currently handle macrons in names
  end
end
