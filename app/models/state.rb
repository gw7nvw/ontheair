# frozen_string_literal: true

# typed: false
class State < ActiveRecord::Base
  require 'csv'

  def self.add_simple_boundaries
    ActiveRecord::Base.connection.execute('update states set boundary_simplified=ST_Simplify("boundary",0.002) where boundary_simplified is null;')
    ActiveRecord::Base.connection.execute('update states set boundary_very_simplified=ST_Simplify("boundary",0.02) where boundary_very_simplified is null;')
    ActiveRecord::Base.connection.execute('update states set boundary_quite_simplified=ST_Simplify("boundary",0.0002) where boundary_quite_simplified is null;')
  end

  def regions
    regions=Region.where('(state_code =  ? or state_code = ?) and dxcc = ?', self.code, self.pnp_code, self.dxcc)
  end

  def self.import(filename)
    CSV.foreach(filename, headers: true) do |row|
      place = row.to_hash
      ActiveRecord::Base.connection.execute("insert into states (dxcc, code, pnp_code, name, boundary) values ('ZL', '" + place['code'] + "','" + place['pnp_code'] + "','" + place['name'].gsub("'", "''") + "',ST_GeomFromText('" + place['WKT'] + "',4326));")
    end; true
  end

  def self.import_vk(filename)
    CSV.foreach(filename, headers: true) do |row|
      place = row.to_hash
      ActiveRecord::Base.connection.execute("insert into states (dxcc, code, name, boundary) values ('VK', '" + place['STE_CODE'] + "','" + place['STE_NAME'].gsub("'", "''") + "',ST_GeomFromText('" + place['WKT'] + "',4326));")
    end; true
  end

  def add_pnp_codes
    ActiveRecord::Base.connection.execute("update states set pnp_code='VK1' where code='ACT'")
    ActiveRecord::Base.connection.execute("update states set pnp_code='VK2' where code='NSW'")
    ActiveRecord::Base.connection.execute("update states set pnp_code='VK3' where code='VIC'")
    ActiveRecord::Base.connection.execute("update states set pnp_code='VK4' where code='QLD'")
    ActiveRecord::Base.connection.execute("update states set pnp_code='VK5' where code='SA'")
    ActiveRecord::Base.connection.execute("update states set pnp_code='VK6' where code='WA'")
    ActiveRecord::Base.connection.execute("update states set pnp_code='VK7' where code='TAS'")
    ActiveRecord::Base.connection.execute("update states set pnp_code='VK8' where code='NT'")
    ActiveRecord::Base.connection.execute("update states set pnp_code='VK9' where code='OTH'")
  end
  def self.update(filename)
    CSV.foreach(filename, headers: true) do |row|
      place = row.to_hash
      if place && place['prefix'] && place['WKT']
        puts place['prefix']
        ActiveRecord::Base.connection.execute("update states set boundary=ST_GeomFromText('" + place['WKT'] + "',4326) where sota_code='" + place['prefix'] + "';")
      end
    end; true
  end

  def self.add_pnp_codes
    names = [['Northland State', 'NL'],
             ['Auckland State', 'AK'],
             ['Waikato State', 'WK'],
             ['Bay of Plenty State', 'BP'],
             ['Gisborne State', 'GI'],
             ["Hawke's Bay State", 'HB'],
             ['Taranaki State', 'TN'],
             ['Manawatū-Whanganui State', 'MW'],
             ['Wellington State', 'WL'],
             ['West Coast State', 'WC'],
             ['Canterbury State', 'CB'],
             ['Otago State', 'OT'],
             ['Southland State', 'SL'],
             ['Tasman State', 'TM'],
             ['Nelson State', 'TM'],
             ['Marlborough State', 'MB'],
             ['Area Outside State', 'CI']]

    State.all.each do |state|
      namelst = names.select { |n| n[0] == state.name }
      next unless namelst && !namelst.empty?
      name = namelst.first
      puts state.name
      puts name[1]
      ActiveRecord::Base.connection.execute("update states set sota_code='" + name[1] + "' where id=" + state.id.to_s + ';')
    end; true
  end

  def assets(dxcc='ZL', at_date = Time.now)
    #  as=Asset.where(state: self.sota_code)
    Asset.find_by_sql [" select * from assets where country='#{dxcc}' and state='#{sota_code}' and minor is not true and (valid_from is null or valid_from<='#{at_date}') and ((valid_to is null and is_active=true) or valid_to>='#{at_date}') "]
  end

  def assets_by_type(type, dxcc='ZL', at_date = Time.now)
    #  as=Asset.where(state: self.sota_code, asset_type: type)
    Asset.find_by_sql [" select * from assets where country='#{dxcc}' and state='#{sota_code}' and asset_type='#{type}' and minor is not true and (valid_from is null or valid_from<='#{at_date}') and ((valid_to is null and is_active=true) or valid_to>='#{at_date}') "]
  end

  def regions
    Region.where(dxcc: dxcc, state_code: code)
  end

  def self.get_assets_with_type(dxcc='ZL', at_date = Time.now)
    Contact.find_by_sql [" select name, type, code_count, site_list from (select a.is_active as is_active, d.sota_code as name, a.asset_type as type, count(distinct(a.code)) as code_count, array_agg(a.code) as site_list from states d inner join assets a on a.state=d.sota_code where a.minor is not true and (a.valid_from is null or a.valid_from<='#{at_date}') and ((a.valid_to is null and a.is_active=true) or a.valid_to>='#{at_date}') and  d.dxcc='#{dxcc}' group by d.sota_code, a.asset_type, a.is_active, a.minor) as foo; "]
  end
  def self.generate_pnp2_sites(dxccs)

    sql = <<-SQL
      SELECT 
       a.code as "regionID",
       a.pnp_code as "regionCode",
       a.name,
       ST_X(ST_Centroid(a.boundary))::varchar as "longitude",
       ST_Y(ST_Centroid(a.boundary))::varchar as "latitude",
       a.dxcc as "dxccPrefix",
       d.iso_code as "countryID",
       d.continent_code as "continentID"
    FROM  states a
    JOIN dxcc_prefixes d ON a.dxcc = d.prefix
    WHERE a.dxcc IN (:dxccs) 
    ORDER BY a.code
    SQL

    # 2. Bind the variables safely (Double-check that start_time and zone are not nil)
    sanitized_sql = sanitize_sql_array([sql, { dxccs: dxccs }])

    # 3. Pull raw string text directly from the execution block
    connection.select_all(sanitized_sql)

  end

end
