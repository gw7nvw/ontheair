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

  def self.get_keys(user, pass, 
    regions = [
      { d: 'ZL1', r: 'HAK' },
      { d: 'ZL1', r: 'HNL' },
      { d: 'ZL1', r: 'HWK' },
      { d: 'ZL1', r: 'HBP' },
      { d: 'ZL1', r: 'HGI' },
      { d: 'ZL1', r: 'HTN' },
      { d: 'ZL1', r: 'HHB' },
      { d: 'ZL1', r: 'HWL' },
      { d: 'ZL3', r: 'HTM' },
      { d: 'ZL3', r: 'HMB' },
      { d: 'ZL3', r: 'HCB' },
      { d: 'ZL3', r: 'HOT' },
      { d: 'ZL3', r: 'HSL' }
    ])
    # d: 'ZL1', r: 'HMW'
    # d: 'ZL3', r: 'HWC'

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
      region = reg[:r]
      dxcc = reg[:d]

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
      asset = Asset.find_by(code: summit[:code])
      if asset
        puts 'found ' + asset.code
        asset.old_code = summit[:id].to_s
        asset.save
      else
        puts 'not found: ' + summit[:code]
      end
    end
  end
end
