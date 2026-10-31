class UserNotificationLink < ApplicationRecord
  before_save :strip_blanks

  scope :matching_spot, ->(spot) {
    where(
      "(continents IS NULL or :continent='' OR continents && ARRAY[:continent::varchar]) AND " \
      "(bands IS NULL OR :band='' OR bands && ARRAY[:band::varchar]) AND " \
      "(modes IS NULL OR :mode='' OR modes && ARRAY[:mode::varchar]) AND " \
      "(spot_types IS NULL OR spot_types && ARRAY[:spot_types::varchar]) AND " \
    "(activator_callsign IS NULL OR EXISTS (
       SELECT 1 FROM unnest(string_to_array(activator_callsign, ',')) AS pattern
       WHERE :activator_callsign LIKE REPLACE(TRIM(pattern), '*', '%')
    )) AND " \
    "(code IS NULL OR EXISTS (
       SELECT 1
       FROM unnest(string_to_array(code, ',')) AS pattern
       CROSS JOIN unnest(ARRAY[:code_array]::varchar[]) AS incoming_code
       WHERE incoming_code LIKE REPLACE(TRIM(pattern), '*', '%')
    ))",
      continent: spot.continent||"",
      band: spot.band||"",
      mode: spot.mode||"",
      spot_types: spot.spot_type,
      activator_callsign: spot.activatorCallsign,
      code_array: spot.code
    )
  }

  def user
    User.find(self.user_id)
  end

  def strip_blanks
    self.bands=self.bands-[ "" ] if self.bands
    self.continents=self.continents-[ "" ] if self.continents
    self.spot_types=self.spot_types-[ "" ] if self.spot_types
    self.modes=self.modes-[ "" ] if self.modes
    self.bands=nil if self.bands.blank?
    self.continents=nil if self.continents.blank?
    self.spot_types=nil if self.spot_types.blank?
    self.modes=nil if self.modes.blank?
    self.code=nil if self.code.blank?
    self.activator_callsign=nil if self.activator_callsign.blank?
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
