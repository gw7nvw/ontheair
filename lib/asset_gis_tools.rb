module AssetGisTools

#Get a 'location' for a park from a boundary.  By default return the
#centroid, but if the centroid does not lie witin the boundary
#then an arbitrary point within the polygon
def calc_location
  location=nil
  if self.id then
    locations=Asset.find_by_sql [ 'select id, CASE
      WHEN (ST_ContainsProperly(boundary, ST_Centroid(boundary)))
      THEN ST_Centroid(boundary)
      ELSE ST_PointOnSurface(boundary)
      END AS location from assets where id='+self.id.to_s ]
    if locations and locations.count>0 then location=locations.first.location else location=nil end
  end
  location
end

def add_sota_activation_zone
  if self.asset_type=="summit" or self.asset_type=="hump" then
    logger.debug self.code
    dem=Asset.get_custom_connection("cps",'dem15','mbriggs',DEMPASSWORD)
    location=self.location
    alt_min=self.altitude-25
    alt_max=5000
    dist_max=0.04 #degrees
    logger.debug " select val, st_astext(geom) as geom from (select (st_dumpaspolygons(st_reclass(st_union(rast),1,'0-#{alt_min}:0,#{alt_min}-#{alt_max}:1','8BUI'))).* from dem16 where st_intersects(rast,st_buffer(ST_GeomFromText('POINT(#{self.location.x} #{self.location.y})',4326),#{dist_max}))) as bar where val=1 and st_contains(geom, ST_GeomFromText('POINT(#{self.location.x} #{self.location.y})',4326)); "
    az_poly=dem.exec_query(" select val, st_astext(geom) as geom from (select (st_dumpaspolygons(st_reclass(st_union(rast),1,'0-#{alt_min}:0,#{alt_min}-#{alt_max}:1','8BUI'))).* from dem16 where st_intersects(rast,st_buffer(ST_GeomFromText('POINT(#{self.location.x} #{self.location.y})',4326),#{dist_max}))) as bar where val=1 and st_contains(geom, ST_GeomFromText('POINT(#{self.location.x} #{self.location.y})',4326)); ")
    if az_poly and az_poly.count>0 and az_poly.first["geom"] then
      logger.debug az_poly.first["geom"]
      boundary=make_multipolygon(az_poly.first["geom"])
      ActiveRecord::Base.connection.execute("update assets set boundary=ST_geomfromtext('#{boundary}',4326) where id=#{self.id.to_s};");  
    end
  end
end


#TODO: should rewrite this to only do assets with has_boundary
def self.add_areas
  ActiveRecord::Base.connection.execute( " update assets set area=ST_Area(ST_Transform(boundary,2193)) where boundary is not null and asset_type!='summit'")
end

def get_access
  #roads
  ActiveRecord::Base.connection.execute("update assets set access_road_ids=(select array_agg(r.id) as road_ids from assets a, roads r where (ST_intersects (a.boundary, r.linestring) or ST_intersects (a.location, r.linestring)) and a.code='#{self.code}') where code='#{self.code}'")

  #legal_roads
  ActiveRecord::Base.connection.execute("update assets set access_legal_road_ids=(select array_agg(r.id) as legal_road_ids from assets a, legal_roads r where (ST_intersects (a.boundary, r.boundary) or ST_intersects (a.location, r.boundary)) and a.code='#{self.code}') where code='#{self.code}'")

  #parks
  ActiveRecord::Base.connection.execute("update assets set access_park_ids=(select array_agg(r.id) as park_ids from assets a, assets r where (ST_intersects (a.boundary, r.boundary) or ST_intersects (a.location, r.boundary)) and a.code='#{self.code}' and r.asset_type='park') where code='#{self.code}'")

  #tracks
  ActiveRecord::Base.connection.execute("update assets set access_track_ids=(select array_agg(r.id) as track_ids from assets a, doc_tracks r where (ST_intersects (a.boundary, r.linestring) or ST_intersects (a.location, r.linestring)) and a.code='#{self.code}') where code='#{self.code}'")

  self.reload
  if self.access_legal_road_ids==nil and self.access_track_ids==nil and self.access_park_ids==nil then
    ActiveRecord::Base.connection.execute("update assets set public_access=false where code='#{self.code}'")
  else
    ActiveRecord::Base.connection.execute("update assets set public_access=true where code='#{self.code}'")
  end
  self.reload
end

def get_access_with_buffer(buffer)
  if self.boundary then
     logger.debug "boundary"
     queryfield='a.boundary'
  else
     queryfield='a.location'
  end

  #roads
  ActiveRecord::Base.connection.execute("update assets set access_road_ids=(select array_agg(r.id) as road_ids from assets a, roads r where ST_DWithin(ST_Transform(#{queryfield},2193), ST_Transform(r.linestring,2193), #{buffer}) and a.code='#{self.code}') where code='#{self.code}'")

  #legal_roads
  ActiveRecord::Base.connection.execute("update assets set access_legal_road_ids=(select array_agg(r.id) as legal_road_ids from assets a, legal_roads r where ST_DWithin(ST_Transform(#{queryfield},2193), ST_Transform(r.boundary,2193), #{buffer}) and a.code='#{self.code}') where code='#{self.code}'")

  #parks
  ActiveRecord::Base.connection.execute("update assets set access_park_ids=(select array_agg(r.id) as park_ids from assets a, assets r where ST_DWithin(ST_Transform(#{queryfield},2193), ST_Transform(r.boundary,2193), #{buffer}) and a.code='#{self.code}' and r.asset_type='park') where code='#{self.code}'")

  #tracks
  ActiveRecord::Base.connection.execute("update assets set access_track_ids=(select array_agg(r.id) as track_ids from assets a, doc_tracks r where ST_DWithin(ST_Transform(#{queryfield},2193), ST_Transform(r.linestring,2193), #{buffer}) and a.code='#{self.code}') where code='#{self.code}'")

  self.reload
  if self.access_legal_road_ids==nil and self.access_track_ids==nil and self.access_park_ids==nil then
    ActiveRecord::Base.connection.execute("update assets set public_access=false where code='#{self.code}'")
  else
    ActiveRecord::Base.connection.execute("update assets set public_access=true where code='#{self.code}'")
  end
  self.reload
end


#fix invalid polygons for all assets
def self.fix_invalid_polygons
    ActiveRecord::Base.connection.execute( "update assets set boundary=st_multi(ST_CollectionExtract(ST_MakeValid(boundary),3)) where id in (select id from assets where ST_IsValid(boundary)=false);")
    ActiveRecord::Base.connection.execute( "update assets set boundary_simplified=st_multi(ST_CollectionExtract(ST_MakeValid(boundary_simplified),3)) where id in (select id from assets where ST_IsValid(boundary_simplified)=false);")
    ActiveRecord::Base.connection.execute( "update assets set boundary_very_simplified=st_multi(ST_CollectionExtract(ST_MakeValid(boundary_very_simplified),3)) where id in (select id from assets where ST_IsValid(boundary_very_simplified)=false);")
end

#add simple boundaries for all assets
def self.add_simple_boundaries
    ActiveRecord::Base.connection.execute( 'update assets set boundary_simplified=ST_Simplify("boundary",0.002) where boundary_simplified is null;')
    ActiveRecord::Base.connection.execute( 'update assets set boundary_very_simplified=ST_Simplify("boundary",0.02) where boundary_very_simplified is null;')
    ActiveRecord::Base.connection.execute( 'update assets set boundary_quite_simplified=ST_Simplify("boundary",0.002) where boundary_quite_simplified is null;')
end

#add simplified boundary for this asset
def add_simple_boundary
    ActiveRecord::Base.connection.execute( 'update assets set boundary_simplified=ST_Simplify("boundary",0.002) where id='+self.id.to_s+';')
    ActiveRecord::Base.connection.execute( 'update assets set boundary_very_simplified=ST_Simplify("boundary",0.02) where id='+self.id.to_s+';')
    ActiveRecord::Base.connection.execute( 'update assets set boundary_quite_simplified=ST_Simplify("boundary",0.002) where id='+self.id.to_s+';')
end

#add areas for all assets
# Calculate area of the asset
#TODO: should rewrite this to only do assets with has_boundary
def add_area
  ActiveRecord::Base.connection.execute( " update assets set area=ST_Area(ST_Transform(boundary,2193)) where boundary is not null and asset_type!='summit' and id="+self.id.to_s)
end

def add_buffered_activation_zone
  logger.debug "update assets set boundary=ST_Transform(ST_Buffer(ST_Transform(a.location,2193),#{self.az_radius*1000}),4326) where a.id=#{self.id}"
 ActiveRecord::Base.connection.execute("update assets a set boundary=ST_Multi(ST_Transform(ST_Buffer(ST_Transform(a.location,2193),#{self.az_radius*1000}),4326)) where a.id=#{self.id}")
end

def make_multipolygon(boundary)
   if boundary[0..6]=="POLYGON" then boundary="MULTIPOLYGON ("+boundary[7..-1]+")" end
   boundary
end


def self.get_custom_connection(identifier, dbname, dbuser, password)
  eval("Custom_#{identifier} = Class::new(ActiveRecord::Base)")
  eval("Custom_#{identifier}.establish_connection(:adapter=>'postgis', :database=>'#{dbname}', " +
      ":username=>'#{dbuser}', :password=>'#{password}')")
  return eval("Custom_#{identifier}.connection")
end

end

