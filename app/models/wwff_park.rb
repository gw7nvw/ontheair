# frozen_string_literal: true

# typed: false
class WwffPark < ActiveRecord::Base
  def park
    Park.find_by(id: napalis_id)
  end

  def find_doc_park
    ps = Crownparks.find_by_sql ["select * from crownparks dp where ST_Within(ST_GeomFromText('" + location.as_text + %q{', 4326), dp."WKT");}]
    if !ps || ps.count.zero?
      puts 'Trying for nearest'
      ps = Crownparks.find_by_sql [%q{ SELECT *
        FROM crownparks dp
        WHERE ST_DWithin("WKT", ST_GeomFromText('} + location.as_text + %q{', 4326), 10000, false)
        ORDER BY ST_Distance("WKT", ST_GeomFromText('} + location.as_text + "', 4326)) LIMIT 50; "]
    end

    if ps && (ps.count > 1)
      puts '==========================================================='
      count = 0
      ps.each do |p|
        puts count.to_s + ' - ' + p.name + ' == ' + name
        count += 1
      end
      puts "Select match (or 'a' to add):"
      id = gets
      if id && (id.length > 1) && (id[0] != 'a')
        ps = [ps[id.to_i]]
      elsif id[0] == 'a'
        nid = ('998' + reference[5..8]).to_i
        p = Park.find_by_id(nid)
        unless p
          p = Park.new
          p.id = nid
          p.is_mr = false
          p.description = 'Imported from WWFF'
        end
        p.name = name
        p.location = location
        p.save
        ps = [p.reload]
      else
        ps = nil
      end
    end

    if !ps || ps.count.zero?
      puts 'Error: FAILED'
      nil
    elsif id && (id[0] == 'a')
      ps[0]
    else
      puts 'Found doc park ' + ps.first.napalis_id.to_s + ' : ' + ps.first.name + ' == ' + name
      Park.find_by_id(ps.first.napalis_id)
    end
  end

  def find_park
    ps = Park.find_by_sql ["select * from parks dp where ST_Within(ST_GeomFromText('" + location.as_text + "', 4326), dp.boundary);"]
    ps = Park.where('name ILIKE ?', name) if !ps || ps.count.zero?
    if !ps || ps.count.zero?
      ps = Park.find_by_sql [" SELECT *
        FROM parks dp
        WHERE ST_DWithin(boundary, ST_GeomFromText('" + location.as_text + "', 4326), 10000, false)
        ORDER BY ST_Distance(boundary, ST_GeomFromText('" + location.as_text + "', 4326)) LIMIT 50; "]
      if ps && ps.count.zero?
        puts '==========================================================='
        count = 0
        ps.each do |p|
          puts count.to_s + ' - ' + p.name + ' == ' + name
          count += 1
        end
        puts 'Select match:'
        gets id
        ps = id && (id.length > 1) ? [ps[id]] : nil
      end
    end
    if ps && ps.count.zero?
      puts 'Found park ' + ps.first.id.to_s + ' : ' + ps.first.name + ' == ' + name
      ps.first
    end
  end

  def self.import
    uri = URI('https://wwff.co/directory')
    params = 'progName=ZLFF&dxccName=ZLFF&refID=Select&newState=ZZ&newCounty=ZZ'

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    req = Net::HTTP::Post.new(uri.path, 'Content-Type' => 'application/x-www-form-urlencoded')

    req.body = params
    res = http.request(req)
    table = res.body.split('Start: template_directory_listing.htm')[1].split('End: template_directory_listing.htm')[0]
    rows = table.split('<tr>')
    rows.each do |row|
      next unless row =~ 'refID'
      code = row.split('value=')[1]
      code = code.split('</td>')[0] if code
      code = code.gsub('\"', '') if code
      code = code.delete('"') if code
      code = code.delete('>') if code

      name = row.split('<td>')[2]
      name = name.split('</td>')[0] if name

      next unless name && code
      puts 'Code: ' + code + ', name: ' + name
      p = WwffPark.find_by(code: code)
      new = false
      unless p
        p = WwffPark.new
        new = true
      end
      p.code = code.strip
      p.name = name.strip
      p.dxcc = 'ZL'
      p.region = 'OC / ZL'
      park = nil
      if new == true
        # p.location='POINT('+feature["Longitude"].to_s+' '+feature["Latitude"].to_s+')'
        # try to match against park
        searchname = name.gsub("'", "''")
        zps = Asset.find_by_sql [" select id, name, code, asset_type, location from assets where asset_type='park' and name='#{searchname}' and is_active=true"]
        if !zps || zps.count.zero?
          # look for best name match
          short_name = searchname
          short_name = short_name.gsub('Forest', '')
          short_name = short_name.gsub('Conservation', '')
          short_name = short_name.gsub('Park', '')
          short_name = short_name.gsub('Area', '')
          short_name = short_name.gsub('Scenic', '')
          short_name = short_name.gsub('Reserve', '')
          short_name = short_name.gsub('Marine', '')
          short_name = short_name.gsub('Wildlife', '')
          short_name = short_name.gsub('Ecological', '')
          short_name = short_name.gsub('National', '')
          short_name = short_name.gsub('Wilderness', '')
          short_name = short_name.gsub('Te', '')
          puts 'no exact match, try like: ' + short_name
          zps = Asset.find_by_sql [" select id, name, code, asset_type, location from assets where asset_type='park' and name ilike '%%#{short_name.strip}%%' and is_active=true"]
          id = nil
          if zps && (zps.count > 1)
            puts '==========================================================='
            count = 0
            zps.each do |pp|
              puts count.to_s + ' - ' + pp.name + ' == ' + self.name
              count += 1
            end
            puts "Select match (or 'a' to skip):"
            id = gets
            zps = [zps[id.to_i]] if id && (id.length > 1) && (id[0] != 'a')
          end
        end
        if !zps || zps.count.zero? || (id[0] == 'a')
          puts 'enter asset id to match: '
          code = gets
          zps = Asset.where(code: code.strip)
        end

        if zps && (zps.count == 1)
          park = zps.first
          p.location = park.location
          puts "Matched #{name} with #{park.name}"
        else
          puts 'Could not find match. No location'
        end
      else
        puts 'Existing WWFF park'
      end
      p.save
      a = Asset.add_wwff_park(p, park)
      next unless new
      a.add_region
      a.add_area
      a.add_links
    end
  end

  def self.import_from_pnp
    pps = all
    pps.each(&:destroy)

    url = 'http://parksnpeaks.org/api/SITES/WWFF'
    data = JSON.parse(open(url).read)
    if data
      data.each do |feature|
        code = feature['ID']
        next unless code && (code[0..1] == 'ZL')
        p = WwffPark.new
        p.code = code
        p.name = feature['Name']
        p.dxcc = feature['State']
        p.region = 'OC / ZL'
        p.location = 'POINT(' + feature['Longitude'].to_s + ' ' + feature['Latitude'].to_s + ')'
        p.save
        a = Asset.add_wwff_park(p)
        a.find_links
      end
    end
  end

  def self.migrate_to_assets
    pps = WwffPark.all
    pps.each do |pp|
      p = Asset.find_by(code: 'ZLP/' + pp.napalis_id.to_s)
      if p
        dup = AssetLink.where(contained_code: pp.code, containing_code: p.code)
        if !dup || dup.count.zero?
          AssetLink.create(contained_code: pp.code, containing_code: p.code)
        end
        dup = AssetLink.where(contained_code: p.code, containing_code: pp.code)
        if !dup || dup.count.zero?
          AssetLink.create(contained_code: p.code, containing_code: pp.code)
        end
        puts pp.code
      else
        puts 'ERROR: no park found for POTA park ' + pp.name
      end
    end
  end
end
