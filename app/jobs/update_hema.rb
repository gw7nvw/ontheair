# frozen_string_literal: true

# typed: true

class UpdateHema
  @queue = :ontheair

  def self.perform
    dxccs = [ "ZL1", "ZL3", "VK1", "VK2", "VK3", "VK5", "VK9" ]
    dxccs.each do |dxcc|
      puts "Fetching DXCC: #{dxcc}"
      Asset.import_hema(Rails.application.credentials.hema_user, Rails.application.credentials.hema_password, dxcc)
      puts "Checking locations for DXCC: #{dxcc}"
      Asset.hema_get_lat_long(Rails.application.credentials.hema_user, Rails.application.credentials.hema_password, dxcc)
      puts "Checking elevations for DXCC: #{dxcc}"
      Asset.hema_get_elevation(dxcc)
    end
  end
end
