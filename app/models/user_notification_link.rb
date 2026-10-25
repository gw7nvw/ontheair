class UserNotificationLink < ApplicationRecord
  before_save :strip_blanks

  scope :matching_spot, ->(spot) {
    where(
      "(continents IS NULL OR continents && ARRAY[:continent]) AND " \
      "(bands IS NULL OR bands && ARRAY[:band]) AND " \
      "(modes IS NULL OR modes && ARRAY[:mode]) AND " \
      "(spot_types IS NULL OR spot_types && :spot_types) AND " \
      "(activator_callsign IS NULL OR :activator_callsign LIKE REPLACE(activator_callsign, '*', '%')) AND " \
      "(code IS NULL OR REPLACE(code, '*', '%') LIKE ANY(ARRAY[:code]))",
      continent: spot.continent,
      band: spot.band,
      mode: spot.mode,
      spot_types: spot.spot_type,
      activator_callsign: spot.activatorCallsign,
      code: spot.code # Pass the spot's array of string codes directly (e.g. ['SOTA/VK-001', 'WWFF/VK-002'])
    )
  }

  def strip_blanks
    self.bands=self.bands-[""] if self.bands
    self.continents=self.continents-[""] if self.continents
    self.spot_types=self.spot_types-[""] if self.spot_types
    self.modes=self.modes-[""] if self.modes
  end

  def priority_name
    case priority
    when -2
      "Lowest"
    when -1
      "Low"
    when 0
      "Normal"
    when 1
      "High"
    else
      "Invalid"
    end
  end

  def self.priority_from_name(name)
    case name
    when "Lowest"
      -2
    when "Low"
      -1
    when "Normal"
      0
    when "High"
      1
    else
      0
    end
  end
end
