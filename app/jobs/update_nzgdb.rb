# frozen_string_literal: true

# typed: true
class UpdateNzgdb
  @queue = :ota_scheduled

  def self.perform()
    Nzgdb.update
    Asset.import_lake(true,false,true)
    Asset.import_island(true,false,true)
  end
end
