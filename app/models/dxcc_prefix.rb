# frozen_string_literal: true

# typed: false
class DxccPrefix < ActiveRecord::Base
  def continent
    Continent.find_by(code: continent_code)
  end

  def self.from_call(callsign)
    callsign=callsign.gsub(/[^a-zA-Z0-9\/]/, '')
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

  def code_name
    self.name+" ("+self.prefix+")"
  end
  def self.get_assets_with_type(dxcc='ZL', at_date = Time.now)
    Contact.find_by_sql [" select name, type, code_count, site_list from (select a.is_active as is_active, d.sota_code as name, a.asset_type as type, count(distinct(a.code)) as code_count, array_agg(a.code) as site_list from states d inner join assets a on a.state=d.sota_code where a.minor is not true and (a.valid_from is null or a.valid_from<='#{at_date}') and ((a.valid_to is null and a.is_active=true) or a.valid_to>='#{at_date}') and  d.dxcc='#{dxcc}' group by d.sota_code, a.asset_type, a.is_active, a.minor) as foo; "]
  end


end
