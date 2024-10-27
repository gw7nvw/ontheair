# frozen_string_literal: false

# typed: false
require 'asset_import_tools.rb'
class SotaPeak < ActiveRecord::Base
  ############################################################################
  # To pull updates from SOTA
  #
  # One step process and now well tested
  #
  # call SotaPeak.import from 'rails console production'
  # - Clears the existing SotaPeak table
  # - will download assets by region (so your region table needs to contain
  #   all the SOTA regions)
  # - Creates list of current summits in SotaPeak table
  # - Adds each summit to Assets table (or updates if existing)
  # - Checks Assets for 'summit' type assets not in SotaPeak table and retires them

  def self.import
    sps = all
    sps.each(&:destroy)
    old_codes = Asset.where(asset_type: 'summit', is_active: true).map(&:code)
    new_codes = []
    srs = SotaRegion.all
    srs.each do |sr|
      url = 'https://api-db2.sota.org.uk/api/regions/' + sr.dxcc + '/' + sr.region + '?client=sotawatch&user=anon'
      data = JSON.parse(open(url).read)
      next unless data
      summits = data['summits']
      puts summits.to_json
      next unless summits 
      summits.each do |s|
        puts "HERE"
        ss = SotaPeak.new
        ss.summit_code = s['summitCode']
        ss.name = s['name']
        ss.short_code = s['shortCode']
        ss.valid_to = s['validTo']
        ss.valid_from = s['validFrom']
        ss.alt = s['altM']
        ss.location = 'POINT(' + s['longitude'].to_s + ' ' + s['latitude'].to_s + ')'
        ss.points = s['points']

        ss.save
        puts 'Add / keep: ' + ss.summit_code
        Asset.add_sota_peak(ss)
        new_codes.push(ss.summit_code)
      end
    end
    removed_codes = old_codes - new_codes
    removed_codes.each do |code|
      a = Asset.find_by(code: code)
      next unless !a.valid_to || (a.valid_to < Time.now)
      a.valid_to = Time.now
      a.is_active = false
      puts 'Retiring: ' + a.code
      a.save
    end
  end
end
