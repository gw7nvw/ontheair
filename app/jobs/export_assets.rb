module ExportAssets

  @queue = :ota_scheduled
  def self.perform
    puts "SCHED JOB: Exporting assets"
    ats=AssetType.where(is_zlota: true)
    assets = Asset.find_by_sql [ "select id, name, code, ST_X(location) as x, ST_Y(location) as y, asset_type from assets where is_active=true and minor=false and asset_type in (#{ats.map{|at| "'"+at.name+"'"}.join(", ")}) order by code asc; "]

    #write csv
    csvfile=asset_to_csv(assets).gsub('""','')
    f = File.open('public/assets/assets.csv', 'w') do |file|
      file.write(csvfile)
    end

    jsonfile=assets.map{|a| a.attributes}.to_json
    f = File.open('public/assets/assets.json', 'w') do |file|
      file.write(jsonfile)
    end

  end

  def self.asset_to_csv(items)
    require 'csv'
    csvtext = ''
    if items && items.first
      columns = []
      items.first.attributes.each_pair do |name, _value|
        if !name.include?('password') && !name.include?('digest') && !name.include?('token') && !name.include?('_link') then columns << name end
      end
      csvtext << columns.to_csv
      items.each do |item|
        fields = []
        item.attributes.each_pair do |name, value|
          if !name.include?('password') && !name.include?('digest') && !name.include?('token') && !name.include?('_link') then fields << value end
        end
        csvtext << fields.to_csv
      end
    end
    csvtext
  end

end
