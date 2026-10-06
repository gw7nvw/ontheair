# frozen_string_literal: true

# typed: true
class UpdateNzgdb
  @queue = :ota_scheduled

  def self.perform()
    Nzgdb.update
    Asset.import_lake(true,false,true)
    #Now update islands
  end
end
