# frozen_string_literal: true

# typed: false
class Hump < ActiveRecord::Base
  require 'csv'

  def self.clean
    #remove deleted assets from humps
    hs=Hump.all
    hs.each do |h|
      puts h.code

      a=Asset.find_by(code: h.code)
      if !a then
        puts "DELETING"
        h.destroy
      end

      if h and a and a.location != h.location
        puts "LOCATION"
        h.location = a.location
        h.save
      end
    end
  end

  def self.get_regions(dxcc)
    regions=[]
    uri = URI("http://www.hema.org.uk/country.jsp")
    http = Net::HTTP.new(uri.host, uri.port)
    req = Net::HTTP::Get.new(uri.path+"?countryCode=#{dxcc}")
    response = http.request(req)
    body = response.body
    table = get_table(body,4)
    row_count = get_row_count(table)
    puts row_count
    (2..row_count).each do |row_num|
      row = get_row(table, row_num)
      col = get_col(row,1)
      contents = get_clean_text(col)
      id_name = contents.split('-') if contents
      if !id_name.blank?
        id = id_name[0].strip
        name = id_name[1].strip
        regions << {id: id, name: name}
      end
    end
    regions
  end

  def self.import(filename)
    CSV.foreach(filename, headers: true) do |row|
      place = row.to_hash
      newplace = {}
      place.each do |key, value|
        key = key.gsub(/[^0-9a-z _]/i, '')
        newplace[key] = value
      end
      p = Hump.find_by(code: newplace['Full Ref'])
      p ||= Hump.new
      puts newplace
      p.name = newplace['Name']
      p.code = newplace['Full Ref']
      p.dxcc = newplace['DXCC']
      p.region = newplace['Region'][1..2]
      p.elevation = newplace['Summit Elevation in metres']
      p.prominence = newplace['Summit Prominence (metres)']
      p.location = "POINT(#{newplace['Longitude     E W']} #{newplace['Latitude         N S']})"
      puts "POINT(#{newplace['Longitude     E W']} #{newplace['Latitude         N S']})"
      p.save
      puts p.name
      puts p.id
      puts p.location
    end
  end

  def self.get_elevation(dxcc)
   regions = get_regions(dxcc)
   regions.each do |region|
    uri = URI("http://www.hema.org.uk/region.jsp?countryCode=#{dxcc}&regionCode=#{region[:id]}")
    http = Net::HTTP.new(uri.host, uri.port)
    req = Net::HTTP::Get.new(uri.path+"?countryCode=#{dxcc}&regionCode=#{region[:id]}")
    response = http.request(req)
    body = response.body
    table = body.split('<table>')[3]
    table = table.split('</table>')[0]
    rows = table.split('<tr>')
    count=1
    rows.each do |row|
      if count>1 
        name = row.split('>')[2]
        name = name.split('<')[0]
        id = name.split(' ')[0]
        name = name[6..-1]
        elevation=row.split("Number'>")[1]|| ""
        elevation = elevation.split('<')[0] || "" if elevation

        code = "#{dxcc}/#{region[:id]}-#{id}"
        a = Asset.find_by(code: code)
        if a then
          a.altitude = elevation.gsub('m','').to_i if (!a.altitude or a.altitude==0) and elevation
          if a.changed?
            puts "SET Altitude to #{elevation.gsub('m','').to_i}"
            a.update_column(:altitude, a.altitude)
          end
        end
      end
      count+=1
    end
   end
  end

  def self.get_lat_long(user, pass, dxcc, update = false)
    uri = URI('http://www.hema.org.uk/indexDatabase.jsp')
    http = Net::HTTP.new(uri.host, uri.port)
    req = Net::HTTP::Get.new(uri.path)
    response = http.request(req)

    cookie = response.get_fields('set-cookie')[0].split('; ')[0] + ';'

    
      uri = URI("http://www.hema.org.uk/mapping.jsp")
    
      http = Net::HTTP.new(uri.host, uri.port)
      req = Net::HTTP::Get.new(
        uri.path + '?countryCode=' + dxcc + '&regionCode=0&summitKey=0&action=&genericKey=',
        'Cookie' => cookie,
        'Host' => 'www.hema.org.uk',
        'Origin' => 'http://www.hema.org.uk'
      )

      response = http.request(req)
      body = response.body
      rows = body.split('var Latitude=')
      rows[1..-1].each do |row|
        fields = row.split(';') 
        lat = fields[0]
        long = fields[1].split('=')[1]
        name = fields[2].split('=')[1]
        old_code = fields[7].split('summitKey=')[1].gsub("'","")
        asset = Asset.find_by(name_id: old_code, name_source: 'hema') 
        if asset 
          if (asset.location==nil or update ==true) then
            asset.location = "POINT (#{long} #{lat})"
            puts "Updating asset #{asset.code} #{asset.name} = #{name}: #{asset.location.to_s}"
            asset.save
            asset.get_access
          end
       else
          puts "Not found: "+old_code  
       end
   end

  end


  def self.get_humps(user, pass, dxcc, update=false)

    regions = get_regions(dxcc)

    uri = URI('http://www.hema.org.uk/indexDatabase.jsp')
    http = Net::HTTP.new(uri.host, uri.port)
    req = Net::HTTP::Get.new(uri.path)
    response = http.request(req)

    cookie = response.get_fields('set-cookie')[0].split('; ')[0] + ';'

    params = 'userID=' + user + '&password=' + pass

    uri = URI('http://www.hema.org.uk/indexDatabase.jsp?logonAction=logon&action=')
    http = Net::HTTP.new(uri.host, uri.port)
    req = Net::HTTP::Post.new(
      uri.path + '?logonAction=logon&action=',
      'Content-Type' => 'application/x-www-form-urlencoded',
      'Cookie' => cookie,
      'Host' => 'www.hema.org.uk',
      'Origin' => 'http://www.hema.org.uk',
      'Referrer' => 'http://www.hema.org.uk/indexDatabase.jsp'
    )
    req.body = params
    response = http.request(req)

    summits = []
    regions.each do |reg|
      region = reg[:id]

      uri = URI('http://www.hema.org.uk/selectSummit.jsp')
      http = Net::HTTP.new(uri.host, uri.port)
      req = Net::HTTP::Get.new(
        uri.path + '?regionCode=' + region + '&action=activationNew&summitKey=0&countryCode=' + dxcc + '&genericKey=0',
        'Cookie' => cookie,
        'Host' => 'www.hema.org.uk',
        'Origin' => 'http://www.hema.org.uk'
      )

      response = http.request(req)
      rows = response.body.split("id='summitKey'")[1].split('</td>')[0].split(/\n/)

      rows.each do |r|
        next unless r['Option value']
        value = r.split("'")[1]
        codename = r.split('>')[1].split('<')[0]
        code = dxcc + '/' + region + '-' + codename[0..2]
        name = codename[6..-1]
        summits += [{ id: value, code: code, name: name }]
      end
    end

    summits.each do |summit|
      if summit[:id].to_i>0 then
        asset = Asset.find_by(code: summit[:code])
        if asset
          puts 'found ' + asset.code
          asset.name_id = summit[:id].to_s
          asset.name_source='hema'
          asset.asset_type="hump"
          asset.is_active=true
          asset.url="assets/"+asset.code.gsub("/","_")
          if asset.changed and update==true
            changes = asset.changes_to_save.transform_values(&:last).except('location')
            changes['updated_at'] = Time.current
            res = asset.update_columns(changes) if changes.any?
          end

        else
          puts 'not found: ' + summit[:code]
          asset = Asset.new
          asset.name_id = summit[:id].to_s
          asset.name_source='hema'
          asset.code = summit[:code]
          asset.name = summit[:name]
          asset.asset_type="hump"
          asset.is_active=true
          asset.url="assets/"+asset.code.gsub("/","_")
          asset.save
          puts "Created: "+asset.code+", "+asset.name
        end
      end
    end
  end
end

  private

  def get_table(body,id)
    this_table=nil
    tables=body.split('<table')
    this_table = tables[id] if tables and tables.count>=id
    this_table=this_table.split('</table>')[0] if this_table
    this_table
  end

  def get_row(body,number)
    rows=body.split('<tr>') if body
    row=rows[number] if rows
    row=row.split('</tr>')[0] if row
  end

  def get_col(body,number)
    rows=body.split(/<td(?:.*?)>/) if  body
    row=rows[number] if rows
    row=row.split('</td>')[0] if row
  end

  def get_table_count(body)
    body.scan("<table").length if body
  end
  def get_row_count(body)
    body.scan("<tr").length if body
  end
  def get_col_count(body)
    body.scan("<td").length if body
  end
  def get_clean_text(body)
    body.gsub(/<[^>]*>/, '').gsub(/\r/,'').gsub(/\n/,'').gsub('&nbsp;','').strip if body
  end

