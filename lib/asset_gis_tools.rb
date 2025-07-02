# frozen_string_literal: true

# typed: false
module AssetGisTools
  # Get a 'location' for a park from a boundary.  By default return the
  # centroid, but if the centroid does not lie witin the boundary
  # then an arbitrary point within the polygon
  def calc_location
    location = nil
    if id
      locations = Asset.find_by_sql ['select id, CASE
        WHEN (ST_ContainsProperly(boundary, ST_Centroid(boundary)))
        THEN ST_Centroid(boundary)
        ELSE ST_PointOnSurface(boundary)
        END AS location from assets where id=' + id.to_s]
      location = locations && locations.count.positive? ? locations.first.location : nil
    end
    location
  end

  # Only used on point assets where we can check if AZ is blank.
  # Polygons will need to call get_access(_with_buffer) manually when needed
  # as we don't want to recalculate it on every save
  def add_activation_zone(force = false)
    asset_test = Asset.find_by_sql [" select (az_boundary is not null) as has_boundary from assets where id=#{id}"]
    if (asset_test.first[:has_boundary] == false) || (force == true)
      if type.ele_buffer
        add_sota_activation_zone(type.ele_buffer)
      else
        add_buffered_activation_zone
      end
    end

    add_az_area

    get_access

  end

  # add activation zone as area contained by contour 24m below summit,
  # surrounding summit.
  def add_sota_activation_zone(buffer = 25)
    if altitude && location
      logger.debug code
      alt_min = altitude - buffer
      alt_max = 5000
      dist_max = 0.04 # degrees
      logger.debug " select val, st_astext(geom) as geom from (select (st_dumpaspolygons(st_reclass(st_union(rast),1,'0-#{alt_min}:0,#{alt_min}-#{alt_max}:1','8BUI'))).* from dem16 where st_intersects(rast,st_buffer(ST_GeomFromText('POINT(#{location.x} #{location.y})',4326),#{dist_max}))) as bar where val=1 and st_contains(geom, ST_GeomFromText('POINT(#{location.x} #{location.y})',4326)); "
      az_poly = Dem15.find_by_sql [" select val, st_astext(geom) as geom from (select (st_dumpaspolygons(st_reclass(st_union(rast),1,'0-#{alt_min}:0,#{alt_min}-#{alt_max}:1','8BUI'))).* from dem16 where st_intersects(rast,st_buffer(ST_GeomFromText('POINT(#{location.x} #{location.y})',4326),#{dist_max}))) as bar where val=1 and st_contains(geom, ST_GeomFromText('POINT(#{location.x} #{location.y})',4326)); "]
      if az_poly && az_poly.count.positive? && az_poly.first['geom']
        logger.debug az_poly.first['geom']
        boundary = make_multipolygon(az_poly.first['geom'])
        ActiveRecord::Base.connection.execute("update assets set az_boundary=ST_geomfromtext('#{boundary}',4326) where id=#{id};")
      end
    end
  end

  # Find any public access areas overlapping the point or the boundary (if present)
  # Add them to the access_###_ids list for the asset
  # direct to db so callback-safe
  def get_access
    # roads
    ActiveRecord::Base.connection.execute("update assets set access_road_ids=(select array_agg(r.id) as road_ids from assets a, roads r where (ST_intersects (a.az_boundary, r.linestring) or ST_intersects (a.location, r.linestring)) and a.code='#{code}') where code='#{code}'")

    # legal_roads
    ActiveRecord::Base.connection.execute("update assets set access_legal_road_ids=(select array_agg(r.id) as legal_road_ids from assets a, legal_roads r where (ST_intersects (a.az_boundary, r.boundary) or ST_intersects (a.location, r.boundary)) and a.code='#{code}') where code='#{code}'")

    # parks
    ActiveRecord::Base.connection.execute("update assets set access_park_ids=(select array_agg(r.id) as park_ids from assets a, assets r where (ST_intersects (a.az_boundary, r.boundary) or ST_intersects (a.location, r.boundary)) and a.code='#{code}' and r.asset_type='park') where code='#{code}'")

    # tracks
    ActiveRecord::Base.connection.execute("update assets set access_track_ids=(select array_agg(r.id) as track_ids from assets a, doc_tracks r where (ST_intersects (a.az_boundary, r.linestring) or ST_intersects (a.location, r.linestring)) and a.code='#{code}') where code='#{code}'")

    reload
    if access_legal_road_ids.nil? && access_track_ids.nil? && access_park_ids.nil?
      ActiveRecord::Base.connection.execute("update assets set public_access=false where code='#{code}'")
    else
      ActiveRecord::Base.connection.execute("update assets set public_access=true where code='#{code}'")
    end
    reload
  end

  # fix invalid polygons for all assets
  def Asset.fix_invalid_polygons
    ActiveRecord::Base.connection.execute('update assets set boundary=st_multi(ST_CollectionExtract(ST_MakeValid(boundary),3)) where id in (select id from assets where ST_IsValid(boundary)=false);')
    ActiveRecord::Base.connection.execute('update assets set boundary_simplified=st_multi(ST_CollectionExtract(ST_MakeValid(boundary_simplified),3)) where id in (select id from assets where ST_IsValid(boundary_simplified)=false);')
    ActiveRecord::Base.connection.execute('update assets set boundary_very_simplified=st_multi(ST_CollectionExtract(ST_MakeValid(boundary_very_simplified),3)) where id in (select id from assets where ST_IsValid(boundary_very_simplified)=false);')
  end

  # add simple boundaries for all assets
  def Asset.add_simple_boundaries
    ActiveRecord::Base.connection.execute('update assets set boundary_simplified=ST_Simplify("boundary",0.002) where boundary_simplified is null;')
    ActiveRecord::Base.connection.execute('update assets set boundary_very_simplified=ST_Simplify("boundary",0.02) where boundary_very_simplified is null;')
    ActiveRecord::Base.connection.execute('update assets set boundary_quite_simplified=ST_Simplify("boundary",0.002) where boundary_quite_simplified is null;')
  end

  # add simplified boundary for this asset
  def add_simple_boundary
    if type.has_boundary
      ActiveRecord::Base.connection.execute('update assets set boundary_simplified=ST_Simplify("boundary",0.002) where id=' + id.to_s + ';')
      ActiveRecord::Base.connection.execute('update assets set boundary_very_simplified=ST_Simplify("boundary",0.02) where id=' + id.to_s + ';')
      ActiveRecord::Base.connection.execute('update assets set boundary_quite_simplified=ST_Simplify("boundary",0.002) where id=' + id.to_s + ';')
    end
  end

  # add areas for all assets
  # Calculate area of the asset
  def add_area
    if type.has_boundary
      asset_test = Asset.find_by_sql [" select (boundary is not null) as has_boundary from assets where id=#{id}"]
      if asset_test.first.has_boundary == true
        ActiveRecord::Base.connection.execute(' update assets set area=ST_Area(geography(boundary)) where id=' + id.to_s)
      end
    end
  end

  # add az_areas for all assets
  # Calculate az_area of the asset
  def add_az_area
    asset_test = Asset.find_by_sql [" select (az_boundary is not null) as has_boundary from assets where id=#{id}"]
    if asset_test.first.has_boundary == true
      ActiveRecord::Base.connection.execute(' update assets set az_area=ST_Area(geography(az_boundary)) where id=' + id.to_s)
    end
  end

  def add_altitude(force = false, read_only = false)
    # if altitude is not entered, calculate it from map
    if location && (!altitude || altitude.to_i.zero? || (force == true))
      # get alt from map if it is blank or 0

      alt_arr = Dem15.find_by_sql ["
        select ST_Value(rast, ST_GeomFromText(?,4326)) rid
          from dem16
          where ST_Intersects(rast,ST_GeomFromText(?,4326));",
                                   location.to_s,
                                   location.to_s]

      self.altitude = alt_arr.first.try(:rid).to_i
      unless read_only then update_column(:altitude, altitude) end # callback-safe write
    end
  end

  def Asset.get_altitude_for_location(location)
    a = Asset.new(location: location)
    a.add_altitude(false, true)
    a.altitude
  end

  def add_buffered_activation_zone
    calc_az_radius=az_radius
    calc_az_radius=0 if calc_az_radius==nil

    if self.type.has_boundary and area and area>0 then
      if calc_az_radius==0
        ActiveRecord::Base.connection.execute("update assets a set az_boundary=boundary where a.id=#{id}")
      else
        ActiveRecord::Base.connection.execute("update assets a set az_boundary=ST_Multi(ST_Transform(ST_Buffer(ST_Transform(a.boundary,utmzone(a.location)),#{calc_az_radius * 1000}),4326)) where a.id=#{id}")
      end
    else
      if calc_az_radius>0 then
        ActiveRecord::Base.connection.execute("update assets a set az_boundary=ST_Multi(ST_Transform(ST_Buffer(ST_Transform(a.location,utmzone(a.location)),#{calc_az_radius * 1000}),4326)) where a.id=#{id}")
      end
    end
  end

  def make_multipolygon(boundary)
    if boundary[0..6] == 'POLYGON' then boundary = 'MULTIPOLYGON (' + boundary[7..-1] + ')' end
    boundary
  end
end
