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
    sql = <<-SQL 
          SELECT a.is_active AS is_active, 
            d.prefix AS name, 
            a.asset_type AS type, 
            COUNT(DISTINCT(a.code)) AS code_count, 
            ARRAY_agg(a.code) AS site_list 
          FROM dxcc_prefixes d 
          INNER JOIN assets a ON a.country=d.prefix 
          WHERE a.minor IS NOT true 
            AND (a.valid_from is null OR a.valid_from<=:at_date) 
            AND ((a.valid_to is null AND a.is_active=true) OR a.valid_to>=:at_date) 
            AND d.prefix=:dxcc 
          GROUP BY d.prefix, a.asset_type, a.is_active, a.minor;
    SQL
    sanitized_sql = sanitize_sql_array([sql, { at_date: at_date, dxcc: dxcc }])

    Asset.find_by_sql [ sanitized_sql ]

  end


end
