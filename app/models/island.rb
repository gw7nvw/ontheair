# frozen_string_literal: true

# typed: false
class Island < ActiveRecord::Base
  def self.get_polygons
    ls = Island.where(is_active: true)
    ls.each do |l|
      islands = IslandPolygon.find_by_sql ["select * from island_polygons where is_active=true and ST_Within(ST_GeomFromText('" + l.WKT.as_text + "',4326), boundary);"]
      if !islands || islands.count.zero?
        islands = IslandPolygon.find_by_sql [" SELECT *
         FROM island_polygons dp
         WHERE is_active=true and ST_DWithin(ST_GeomFromText('" + l.WKT.as_text + "', 4326), boundary, 5000, false)
         ORDER BY ST_Distance(ST_GeomFromText('" + l.WKT.as_text + "', 4326), boundary) LIMIT 50; "]
      end
      next unless islands && islands.count.zero?
      found = false
      islands.each do |island|
        l_name = l.name.tr('ū', 'u')
        l_name = l_name.gsub(' / ', ' ')
        l_name = l_name.tr('/', ' ')
        l_name = l_name.gsub(' (', ' ')
        l_name = l_name.gsub(' (', ' ')
        l_name = l_name.tr(')', ' ')
        l_name = l_name.tr(')', ' ')
        l_name = l_name.gsub(/[^0-9a-z]/i, '').gsub('Islands', '').gsub('Island', '')
        island_name = island.name.tr('ū', 'u')
        island_name = island_name.gsub(' / ', ' ')
        island_name = island_name.tr('/', ' ')
        island_name = island_name.gsub(' (', ' ')
        island_name = island_name.gsub(' (', ' ')
        island_name = island_name.tr(')', ' ')
        island_name = island_name.tr(')', ' ')
        island_name = island_name.gsub(/[^0-9a-z]/i, '').gsub('Islands', '').gsub('Island', '')
        island_arr = island_name.split(' ').sort
        l_arr = l_name.split(' ').sort

        next unless (found == false) && ((l_name == island_name) || (island_arr & l_arr == l_arr) || island_arr & l_arr == island_arr || l_name.include?(island_name) || island_name.include?(l_name))

        if l.name != island.name then puts 'Matched ' + (l.name || 'unnamed') + ' with ' + (island.name || 'unnamed') end
        l.boundary = island.boundary
        l.save
        found = true
      end
      if found == false then puts 'Failed to find ' + (l.name || 'unnamed') + '. Best was ' + islands.first.name end
    end
    true
  end

  def self.import
    Nzgdb.where(feat_type: 'island', is_active: true).all do |ni|
      i = Island.find_by(name_id: ni.id)
      if !i
        i = Island.new(ni.attributes.except(:id))
        puts 'New: ' + i.name
      else
        i.assign_attributes(ni.attributes.except(:code, :id))
      end
      unless i.code
        i.code = 'ZLI/' + i.name_id.rjust(5, '0')
        puts 'Added entry: ' + i.code
      end
      # i.save
    end

    Island.all.each do |i|
      nz = Nzgdb.find_by(name_id: i.id, is_active: true)
      unless nz
        puts 'DELETE: ' + i.name + ' - ' + (i.is_active == true ? 'ACTIVE' : 'INACTIVE')
        i.is_active = false
      end
      # i.save
    end; true
  end
end
