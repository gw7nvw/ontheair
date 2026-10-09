# frozen_string_literal: true

# typed: false
class LakePolygon < ActiveRecord::Base
  require 'csv'
  establish_connection :zl_gis

  def self.import(filename)
    count = 0
    CSV.foreach(filename, headers: true) do |row|
      h = row.to_hash
      boundary = h.first[1]
      if boundary[0..6] == 'POLYGON' then boundary = 'MULTIPOLYGON (' + boundary[8..-1] + ')' end
      dup = LakePolygon.find_by(topo50_fid: h['t50_fid'])
      unless dup
        LakePolygon.create(name: h['name'], topo50_fid: h['t50_fid'], boundary: boundary)
        count += 1
        if count == 100
          print '.'
          $stdout.flush
          count = 1
        end
      end
    end
    true
  end

  def self.mark
    ActiveRecord::Base.connection.execute('update lake_polygons set is_active=true where name is not null;')
  end

  def self.merge_duplicates
    ls = LakePolygon.where(is_active: true)
    ls.each do |l|
      l.reload
      next unless l.is_active && l.name && !l.name.empty?
      # print '.'; $stdout.flush

      ls = LakePolygon.find_by_sql ["select l2.* from lake_polygons l1 inner join lake_polygons l2 on (ST_Intersects(l1.boundary, l2.boundary) and  unaccent(l1.name)=unaccent(l2.name) and l1.id!=l2.id) where l1.id='" + l.id.to_s + "';"]

      next unless ls && ls.count.positive?
      # print '#'
      # $stdout.flush
      ids = ls.map(&:id).join(',')
      ids = ids + ',' + l.id.to_s
      ids.split(',').each do |l2|
        areas = LakePolygon.find_by_sql [' select ST_Area(boundary) as id from lake_polygons where id in (' + l2 + '); ']
        puts 'Areas before merge: ' + areas.first.id.to_s
      end

      comb = LakePolygon.find_by_sql [' select st_multi(st_buffer(ST_Union(st_buffer(boundary,0,00001)),-0.00001)) as boundary from lake_polygons where id in (' + ids + '); ']
      poly = comb.first.boundary.as_text
      ls.each do |l2|
        l2.is_active = false
        l2.save
        puts 'Merged and deleted ' + (l2.name || 'unnamed') + ' ' + l2.id.to_s + ' as duplicate of ' + (l.name || 'unnamed') + l.id.to_s
      end
      l.boundary = poly
      l.save
      areas = LakePolygon.find_by_sql [' select ST_Area(boundary) as id from lake_polygons where id in (' + l.id.to_s + '); ']
      puts 'Area after merge: ' + areas.first.id.to_s
    end
    true
  end
end
