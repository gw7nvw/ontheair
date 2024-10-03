# frozen_string_literal: true

# typed: false
class DxccPrefix < ActiveRecord::Base
  def continent
    Continent.find_by(code: continent_code)
  end

  def self.from_call(callsign)
    p = DxccPrefix.find_by_sql ["select * from dxcc_prefixes where '#{callsign}' like CONCAT(prefix,'%%') order by length(prefix) desc limit 1;"]
    p ? p.first : nil
  end

  def self.name_from_call(callsign)
    p = from_call(callsign)
    name = if p
             p.name + ' (' + p.continent.name + ')'
           else
             'Unrecognised callsign prefix'
           end
    name
  end

  def self.continent_from_call(callsign)
    p = from_call(callsign)
    name = if p
             p.continent_code
           else
             ''
           end
    name
  end
end
