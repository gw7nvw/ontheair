# frozen_string_literal: true

# typed: false
class Park < ActiveRecord::Base
  #  set_rgeo_factory_for_column(:boundary, RGeo::Geographic.spherical_factory(:srid => 4326, :proj4=> '+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs', :has_z_coordinate => false))

  # single 7-digit sequence base don napalis_id
  def get_code
    'ZLP/' + id.to_s.rjust(7, '0')
  end

  # ZLP/XX-#### code based on region
  def self.add_dist_codes
    parks = Park.find_by_sql [" select id,name,region from parks where dist_code='' or dist_code is null order by coalesce(ST_Area(boundary),0) desc"]
    parks.each do |p|
      code = get_next_dist_code(p.region)
      ActiveRecord::Base.connection.execute("update parks set dist_code='" + code + "' where id=" + p.id.to_s + ';')
      puts code + ' - ' + p.name
    end
  end

  def self.get_next_dist_code(region)
    region = 'ZZ' if !region || (region == '')
    last_codes = Park.find_by_sql [" select dist_code from parks where dist_code like 'ZLP/" + region + "-%%' and dist_code is not null order by dist_code desc limit 1;"]
    last_code = if last_codes && last_codes.count.positive? && last_codes.first.dist_code
                  last_codes.first.dist_code
                else
                  'ZLP/' + region + '-0000'
                end
    next_code = last_code[0..6] + (last_code[7..10].to_i + 1).to_s.rjust(4, '0')
    next_code
  end

  def codename
    code + ' - ' + name
  end

  def doc_park
    Crownpark.find_by(napalis_id: id)
  end

  def self.add_centroids
    ps = Park.all
    ps.each do |p|
      location = p.calc_location
      if location
        p.location = location
        p.save
      end
    end
    true
  end

  def self.add_regions
    count = 0
    a = Park.first_by_id
    while a
      # puts a.code+" "+count.to_s
      count += 1
      a.add_region
      a = Park.next(a.id)
    end
  end

  def add_region
    if location then region = Region.find_by_sql [" SELECT *
     FROM regions dp
     WHERE ST_DWithin(ST_GeomFromText('" + location.as_text + "', 4326), boundary, 20000, false)
     ORDER BY ST_Distance(ST_GeomFromText('" + location.as_text + "', 4326), boundary) LIMIT 50; "]
    else
      puts 'ERROR: place without location. Name: ' + name + ', id: ' + id.to_s
    end

    if region && region.count.positive? && !(self.region.nil? || (self.region == '')) && (self.region != region.first.sota_code)
      puts 'Not overwriting mismatched regions: ' + code + ' ' + name + ' ' + self.region + ' ' + region.first.sota_code
    end

    if region && region.count.positive? && (self.region.nil? || (self.region == ''))
      ActiveRecord::Base.connection.execute("update parks set region='" + region.first.sota_code + "', dist_code=null where id=" + id.to_s)
      puts 'updating record ' + id.to_s + ' ' + name
    end
  end

  def self.merge_crownparks
    count = 0
    hundreds = 0
    parks = Crownpark.find_by_sql [' select id from crownparks; ']
    cc = 0
    uc = 0

    parks.each do |pid|
      park = Crownpark.find_by_id(pid.id)
      count += 1
      if count >= 100
        count = 0
        hundreds += 1
        puts 'Records: ' + (hundreds * 100).to_s
      end

      # p=self.find_by_id(park.NaPALIS_ID)
      p = find_by_id(park.napalis_id)
      # create if needed
      unless p
        # p=self.create(id: park.NaPALIS_ID, name: park.Name)
        p = create(id: park.napalis_id, name: park.name)
        cc += 1
      end

      # update atrribtes
      # if park.Section=="S24_3_FIXED_MARGINAL_STRIP" or park.Local_Purp!=nil then
      p.is_mr = if (park.section == 's.24(3) - Fixed Marginal Strip') || (park.section == 's.23 - Local Purpose Reserve') || (park.section == 's.22 - Government Purpose Reserve') || (park.section == 's.176(1)(a) - Unoccupied Crown Land') || park.name.upcase['GRAVEL']
                  true
                else
                  false
                end
      p.owner = if park.ctrl_mg_vst.nil? || park.ctrl_mg_vst.casecmp('NO').zero? || park.ctrl_mg_vst.casecmp('NULL').zero?
                  'DOC'
                else
                  park.ctrl_mg_vst
                end
      p.is_active = park.is_active
      p.master_id = park.master_id
      p.location = p.calc_location unless p.location
      p.code = p.get_code unless p.code
      pa = Park.find_by_sql ['select ST_Area(boundary)  as area from parks where id=' + p.id.to_s]
      cpa = Crownpark.find_by_sql ['select ST_Area("WKT") as area from crownparks where id=' + park.id.to_s]
      if pa.first.area != cpa.first.area
        print '#'
        $stdout.flush
        p.boundary = park.WKT
        p.save
      else
        print '.'
        $stdout.flush
        ActiveRecord::Base.connection.execute('update parks set id=' + p.id.to_s + ", name='" + p.name.gsub("'", "''") + "', is_mr=" + p.is_mr.to_s + ", owner='" + p.owner.gsub("'", "''") + "', is_active=" + p.is_active.to_s + ', master_id=' + (p.master_id ? p.master_id.to_s : 'null') + ", location=ST_GeomFromText('" + (p.location || '').as_text + "', 4326), code='" + p.code + "' where id=" + p.id.to_s)
      end
      uc += 1
      # p.add_region
    end

    puts 'Created ' + cc.to_s + ' rows, updated ' + uc.to_s + ' rows'
    true
  end

  def all_boundary
    if boundary.nil?
      boundarys = Crownpark.find_by_sql ['select id, ST_AsText("WKT") as "WKT" from crownparks where napalis_id=' + id.to_s]
      boundary = boundarys && boundarys.count.positive? ? boundarys.first.WKT : nil
    else
      boundary = self.boundary
    end
    boundary || ''
  end

  def simple_boundary
    boundary = nil
    if id
      if self.boundary.nil?
        rnd = 0.0002
        boundarys = Crownpark.find_by_sql ['select id, ST_AsText(ST_Simplify("WKT", ' + rnd.to_s + ')) as "WKT" from crownparks where napalis_id=' + id.to_s]
        boundary = boundarys && boundarys.count.positive? ? boundarys.first.WKT : nil
      else
        boundary = self.boundary
      end
    end
    boundary || ''
  end

  def calc_location
    location = nil
    if id
      if boundary.nil?
        locations = Crownpark.find_by_sql ['select id, CASE
                  WHEN (ST_ContainsProperly("WKT", ST_Centroid("WKT")))
                  THEN ST_Centroid("WKT")
                  ELSE ST_PointOnSurface("WKT")
                END AS  "WKT" from crownparks where napalis_id=' + id.to_s]
        if locations && locations.count.positive?
          location = locations.first.WKT
        else
          location = nil
          puts 'ERROR: failed to find ' + id.to_s
        end
      else
        locations = Park.find_by_sql ['select id, CASE
                  WHEN (ST_ContainsProperly(boundary, ST_Centroid(boundary)))
                  THEN ST_Centroid(boundary)
                  ELSE ST_PointOnSurface(boundary)
                END AS location from parks where id=' + id.to_s]
        location = locations && locations.count.positive? ? locations.first.location : nil
      end
    end
    location
  end

  def self.prune_parks(test)
    ops = []
    ps = Park.all
    ps.each do |p|
      cps = Crownpark.where(napalis_id: p.id)
      if cps && cps.count.positive?

      elsif p.boundary.nil?
        puts 'Orphan found :' + p.id.to_s
        ops.push(p.id)
        unless test
          p.is_active = false
          p.save
        end
      else
        puts 'Local definition found :' + p.id.to_s
      end
    end
    ops
  end

  def self.first_by_id
    Park.where('id > ?', 0).order(:id).first
  end

  def self.next(id)
    Park.where('id > ?', id).order(:id).first
  end

  def self.add_ak_parks
    ps = AkMaps.all
    ps.each do |park|
      p = park.code && (park.code != '') ? Park.find_by(dist_code: park.code) : nil
      unless p
        p = Park.new
        puts 'New park'
      end
      p.name = park.name
      p.boundary = park.WKT
      p.dist_code = park.code
      p.is_active = true
      p.is_mr = false
      p.owner = 'Auckland Regional Council'
      p.location = park.location
      p.save
      p.add_region
      p.reload
      if p.dist_code.nil? || (p.dist_code == '')
        p.dist_code = Park.get_next_dist_code(p.region)
        p.save
      end
      puts 'Added park :' + p.id.to_s + ' - ' + p.name
    end
  end
end
