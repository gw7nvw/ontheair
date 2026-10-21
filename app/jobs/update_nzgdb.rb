# frozen_string_literal: true

# typed: true

class UpdateNzgdb
  @queue = :ontheair

  def self.perform
    Nzgdb.update
    Asset.import_from_nzgdb("lake", "Lake", true, false, true)
    Asset.import_from_nzgdb("island", "Island", true, false, true)
  end
end
