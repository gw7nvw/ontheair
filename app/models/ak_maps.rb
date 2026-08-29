# frozen_string_literal: true

# typed: false
class AkMaps < ActiveRecord::Base
  def self.boundary_import(file)
    h = []
    CSV.foreach(file, headers: true) do |row|
      h.push(row.to_hash)
    end

    h.each do |park|
      p = AkMaps.new
      p.WKT = park['WKT']
      p.name = park['NAME']

      p.save
      puts 'Added AKpark :' + p.id.to_s
    end
  end

  def self.regional_park_import(file)
    h = []
    CSV.foreach(file, headers: true) do |row|
      h.push(row.to_hash)
    end

    h.each do |park|
      p = Asset.find_by(name: park['SiteName'], asset_type: 'park')
      if !p
        p = Asset.new
        p.name = park['SiteName']
        puts 'Added AKpark :' + p.name
      else
        puts 'Updated AKpark :' + p.name
      end
      p.boundary = park['WKT']
      p.asset_type = 'park'
      p.region = 'AK'
      if p.code.nil?
        p.code = Asset.get_next_code('park', 'AK')
        puts p.code
      end
      p.safecode = p.code.tr('/', '_')
      p.url = 'assets/' + p.safecode
      p.is_active = true
      p.category = 'Auckland Regional Council'
      p.location = p.calc_location

      p.save
    end
  end

  def self.get_centroids
    as = AkMaps.all
    as.each do |a|
      next if a.location
      puts a.id
      location = a.get_centroid
      if location
        a.location = location
        a.save
      end
    end
  end

  def get_centroid
    location = nil
    if id
      locations = AkMaps.find_by_sql ['select id, CASE
                WHEN (ST_ContainsProperly("WKT", ST_Centroid("WKT")))
                THEN ST_Centroid("WKT")
                ELSE ST_PointOnSurface("WKT")
              END AS location from ak_maps where id=' + id.to_s]
      location = locations && locations.count.positive? ? locations.first.location : nil
    end
    location
  end

  def self.merge_nearby
    count = 0
    ls = AkMaps.all
    puts ls.count
    ls.each do |l|
      l = AkMaps.find_by_id(l.id)
      count += 1
      puts count
      next unless l&.name && !l.name.empty?
      ls = AkMaps.find_by_sql [' SELECT cp2.id from ak_maps cp1
       inner join ak_maps cp2
       ON (cp2.name = cp1.name) and cp2.id != cp1.id and ST_DWithin(cp1."WKT",cp2."WKT", 20000, false)
       where cp1.id= ' + l.id.to_s + ';']

      next unless !ls.nil? && ls.count.positive?
      ids = ls.map(&:id).join(',')
      ids = ids + ',' + l.id.to_s
      ids.split(',').each do |l2|
        areas = AkMaps.find_by_sql [' select ST_Area("WKT") as id from ak_maps where id in (' + l2 + '); ']
        puts 'Areas before merge: ' + areas.first.id.to_s
      end

      ActiveRecord::Base.connection.execute('update ak_maps set "WKT"=(select st_multi(ST_CollectionExtract(st_collect("WKT"),3)) as "WKT" from ak_maps where id in (' + ids + ')) where id=' + l.id.to_s + '; ')
      ls.each do |ll|
        l2 = AkMaps.find_by_id(ll)
        puts 'Merged and deleted ' + (l2.name || 'unnamed') + ' ' + l2.id.to_s + ' as duplicate of ' + (l.name || 'unnamed') + l.id.to_s
        l2.destroy
      end
      badids = AkMaps.find_by_sql [' select id from ak_maps where id=' + l.id.to_s + ' and ST_IsValid("WKT")=false; ']
      if badids && badids.count.positive?
        puts 'Created invalid geometry'
        ActiveRecord::Base.connection.execute('update ak_maps set "WKT"=st_multi(ST_CollectionExtract(ST_MakeValid("WKT"),3)) where id=' + badids.first.id.to_s + ';')
      end

      areas = AkMaps.find_by_sql [' select ST_Area("WKT") as id from ak_maps where id in (' + l.id.to_s + '); ']
      puts 'Area after merge: ' + areas.first.id.to_s
    end
    true
  end
end
