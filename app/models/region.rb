# frozen_string_literal: true

# typed: false
class Region < ActiveRecord::Base
  require 'csv'

  def self.add_simple_boundaries
    ActiveRecord::Base.connection.execute('update regions set boundary_simplified=ST_Simplify("boundary",0.002) where boundary_simplified is null;')
    ActiveRecord::Base.connection.execute('update regions set boundary_very_simplified=ST_Simplify("boundary",0.02) where boundary_very_simplified is null;')
    ActiveRecord::Base.connection.execute('update regions set boundary_quite_simplified=ST_Simplify("boundary",0.0002) where boundary_quite_simplified is null;')
  end

  def self.import(filename)
    CSV.foreach(filename, headers: true) do |row|
      place = row.to_hash
      ActiveRecord::Base.connection.execute("insert into regions (regc_code, name, boundary) values ('" + place['REGC_code'] + "','" + place['REGC_name'].gsub("'", "''") + "',ST_GeomFromText('" + place['WKT'] + "',4326));")
    end; true
  end

  def self.update(filename)
    CSV.foreach(filename, headers: true) do |row|
      place = row.to_hash
      if place && place['prefix'] && place['WKT']
        puts place['prefix']
        ActiveRecord::Base.connection.execute("update regions set boundary=ST_GeomFromText('" + place['WKT'] + "',4326) where sota_code='" + place['prefix'] + "';")
      end
    end; true
  end

  def self.add_sota_codes
    names = [['Northland Region', 'NL'],
             ['Auckland Region', 'AK'],
             ['Waikato Region', 'WK'],
             ['Bay of Plenty Region', 'BP'],
             ['Gisborne Region', 'GI'],
             ["Hawke's Bay Region", 'HB'],
             ['Taranaki Region', 'TN'],
             ['Manawatū-Whanganui Region', 'MW'],
             ['Wellington Region', 'WL'],
             ['West Coast Region', 'WC'],
             ['Canterbury Region', 'CB'],
             ['Otago Region', 'OT'],
             ['Southland Region', 'SL'],
             ['Tasman Region', 'TM'],
             ['Nelson Region', 'TM'],
             ['Marlborough Region', 'MB'],
             ['Area Outside Region', 'CI']]

    Region.all.each do |region|
      namelst = names.select { |n| n[0] == region.name }
      next unless namelst && !namelst.empty?
      name = namelst.first
      puts region.name
      puts name[1]
      ActiveRecord::Base.connection.execute("update regions set sota_code='" + name[1] + "' where id=" + region.id.to_s + ';')
    end; true
  end

  def assets(at_date = Time.now)
    #  as=Asset.where(region: self.sota_code)
    Asset.find_by_sql [" select * from assets where region='#{sota_code}' and minor is not true and (valid_from is null or valid_from<='#{at_date}') and ((valid_to is null and is_active=true) or valid_to>='#{at_date}') "]
  end

  def assets_by_type(type, at_date = Time.now)
    #  as=Asset.where(region: self.sota_code, asset_type: type)
    Asset.find_by_sql [" select * from assets where region='#{sota_code}' and asset_type='#{type}' and minor is not true and (valid_from is null or valid_from<='#{at_date}') and ((valid_to is null and is_active=true) or valid_to>='#{at_date}') "]
  end

  def districts
    District.where(region_code: sota_code)
  end

  def self.get_assets_with_type(at_date = Time.now)
    Contact.find_by_sql [" select name, type, code_count, site_list from (select a.is_active as is_active, d.sota_code as name, a.asset_type as type, count(distinct(a.code)) as code_count, array_agg(a.code) as site_list from regions d inner join assets a on a.region=d.sota_code where a.minor is not true and (a.valid_from is null or a.valid_from<='#{at_date}') and ((a.valid_to is null and a.is_active=true) or a.valid_to>='#{at_date}') group by d.sota_code, a.asset_type, a.is_active, a.minor) as foo; "]
  end
end
