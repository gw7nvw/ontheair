module ExportAssets

  @queue = :ota_scheduled
  def self.perform
    puts "SCHED JOB: Exporting assets"
    ats=AssetType.where(is_zlota: true)
    assets = Asset.find_by_sql [ "select id, name, code, ST_X(location) as x, ST_Y(location) as y, asset_type from assets where is_active=true and minor=false and asset_type in (#{ats.map{|at| "'"+at.name+"'"}.join(", ")}) order by code asc; "]
    polo_assets = Asset.find_by_sql [ "select a.code as reference, (case a.is_active when true then 'active' else  'inactive' end) as status, a.name, concat('ZLOTA - ',a.asset_type) as program, 'ZL' as dxcc, a.region as state, d.name as county, 'OC' as continent,  ST_Y(a.location) as latitude, ST_X(a.location) as longitude, '170' as dxccEnum from assets a left join districts d on d.district_code=a.district where minor=false and asset_type in (#{ats.map{|at| "'"+at.name+"'"}.join(", ")}) order by code asc; "]
    #write csv
    csvfile=asset_to_csv(assets).gsub('""','')
    f = File.open('public/assets/assets.csv', 'w') do |file|
      file.write(csvfile)
    end

    csvfile=asset_to_csv(polo_assets).gsub('""','')
    f = File.open('public/assets/polo_assets.csv', 'w') do |file|
      file.write(csvfile)
    end

    jsonfile=assets.map{|a| a.attributes}.to_json
    f = File.open('public/assets/assets.json', 'w') do |file|
      file.write(jsonfile)
    end

  end

  def self.asset_to_polo_csv(items)
    
  end

  def self.asset_to_csv(items)
    require 'csv'
    csvtext = ''
    if items && items.first
      columns = []
      items.first.attributes.each_pair do |name, _value|
        if !name.include?('password') && !name.include?('digest') && !name.include?('token') && !name.include?('_link') && name!='id' then columns << name end
      end
      csvtext << columns.to_csv
      items.each do |item|
        fields = []
        item.attributes.each_pair do |name, value|
          if !name.include?('password') && !name.include?('digest') && !name.include?('token') && !name.include?('_link') && name!='id' then fields << value end
        end
        csvtext << fields.to_csv
      end
    end
    csvtext
  end

end
