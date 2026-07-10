#class AustraliaDem < ApplicationRecord
class AustraliaDem < ActiveRecord::Base

  establish_connection :dem15

  # Explicitly set table name if it does not follow standard Rails pluralization
  self.table_name = 'public.australia_dem'


#####
# UTILITIES TO HANDLE COP30 DEM FOR AUSTRALIA AS TEMPORARY TABLE
#
# AustraliaDem.prepare_table
#
# AustraliaDem.tile_loaded?(lat, long) -> true / false
#
# AustraliaDem.download_tile(-33, 145)
#
# AustraliaDem.load_to_postgis(-33, 145)
#
# AustraliaDem.get_point_elevation(-32.5,145)
#
# AustraliaDem.delete_temp_file(-33, 145)
#
# AustraliaDem.remove_from_postgis(-33, 145)
#
  # Base URL for the public Copernicus AWS S3 endpoint
COPERNICUS_BASE_URL = "https://copernicus-dem-30m.s3.eu-central-1.amazonaws.com"
TEMP_DIR="/tmp"

  class << self

  def prepare_table
    lat = -33
    long = 145
    # 2. Path to any temporary downloaded GLO-30 tile file
    filename = build_filename(lat,long)
    local_file_path = File.join(TEMP_DIR, filename)
    download_tile(lat, long)
   
    db_config = self.connection_config
    host     = db_config[:host] || 'localhost'
    user     = db_config[:username]
    database = db_config[:database]
    password = db_config[:password]

    # 3. Shell out to initialize the table structure safely
    cmd = "raster2pgsql -F -p -s 4326 -t 100x100 #{local_file_path} public.australia_dem | psql -h #{host} -U #{user} -d #{database}"
    system({"PGPASSWORD" => password}, cmd)

    delete_temp_file(lat, long)

    # 4. Add the lookup index
    connection.execute "CREATE INDEX australia_dem_filename_idx ON public.australia_dem (filename);"
  end

  def tile_loaded?(lat, long)
      filename = build_filename(lat,long)
      query = "SELECT EXISTS(SELECT 1 FROM australia_dem WHERE filename = '#{filename}' LIMIT 1);"
      res  = connection.execute(query)
      if res.first["exists"]=='t' then true else false end
  end

    # Downloads the tile from AWS S3, skipping safely if it's an ocean tile (404)
  def download_tile(lat, long)
      require 'net/http'
      require 'uri'
      tile_name = build_tile_name(lat,long)
      filename = build_filename(lat,long)
      local_file_path = File.join(TEMP_DIR, filename)

      uri = URI("#{COPERNICUS_BASE_URL}/#{tile_name}/#{tile_name}.tif")

      Net::HTTP.start(uri.host, uri.port, use_ssl: true) do |http|
        request = Net::HTTP::Get.new(uri)
        http.request(request) do |response|
          return false if response.code == "404"

          if response.code == "200"
            File.open(local_file_path, "wb") do |file|
              response.read_body { |chunk| file.write(chunk) }
            end
            return true
          end
        end
      end
      false
  end

    # Invokes raster2pgsql using the database configuration matching the current Rails environment
  def load_to_postgis(lat, long)
      filename = build_filename(lat,long)
      local_file_path = File.join(TEMP_DIR, filename)

      db_config = self.connection_config
      host     = db_config[:host] || 'localhost'
      user     = db_config[:username]
      database = db_config[:database]
      password = db_config[:password]

      # -s 4326: WGS84, -a: Append mode, -M: Vacuum stats, -t 100x100: Tile size
      cmd = "raster2pgsql -F -s 4326 -a -M -t 100x100 #{local_file_path} australia_dem | psql -h #{host} -U #{user} -d #{database} > /dev/null 2>&1"
      
      system({"PGPASSWORD" => password}, cmd)
  end

  def delete_temp_file(lat, long)
      filename = build_filename(lat,long)
      local_file_path = File.join(TEMP_DIR, filename)
      cmd = "rm #{local_file_path}"
      system(cmd)
  end

  # Removes the loaded rows for a specific file and executes a safe concurrent VACUUM
  def remove_from_postgis(lat, long)
      filename = build_filename(lat,long)
      query = "DELETE FROM #{table_name} WHERE filename = '#{filename}'"
      res  = connection.execute(query)
      connection.execute("VACUUM #{table_name};")
      res
  end

  def get_point_elevation(lat, long)
      query = %Q{     SELECT
         ST_Value(rast, 1, ST_SetSRID(ST_MakePoint(#{long}, #{lat}), 4326)) AS elevation_meters
         FROM public.australia_dem
         WHERE ST_Intersects(rast, ST_SetSRID(ST_MakePoint(#{long}, #{lat}), 4326));
      }
      res  = connection.execute(query)
      res.first
  end

  # Safely reclaims space without locking reads/writes on the table
  def vacuum_table
      # VACUUM cannot be run inside a transaction block in PostgreSQL
      connection.execute("VACUUM #{table_name};")
  end

    # Helper to construct standard Copernicus naming strings
    def build_tile_name(lat, lon)
      lat_dir = lat >= 0 ? "N" : "S"
      lon_dir = lon >= 0 ? "E" : "W"
      
      lat_str = format("%s%02d_00", lat_dir, lat.abs)
      lon_str = format("%s%03d_00", lon_dir, lon.abs)
      
      "Copernicus_DSM_COG_10_#{lat_str}_#{lon_str}_DEM"
    end

    def build_filename(lat, lon)
      lat_dir = lat >= 0 ? "N" : "S"
      lon_dir = lon >= 0 ? "E" : "W"

      lat_str = format("%s%02d_00", lat_dir, lat.abs)
      lon_str = format("%s%03d_00", lon_dir, lon.abs)

      "Copernicus_DSM_COG_10_#{lat_str}_#{lon_str}_DEM.tif"
    end 
  
    def clear_table
      query = "DELETE FROM #{table_name}"
      res  = connection.execute(query)
      connection.execute("VACUUM #{table_name};")
    end

  end

  def self.get_sota_az(point_lat,point_long, elevation)
    buffer = 25
    boundary = nil

    lat_i=point_lat.to_i
    long_i=point_long.to_i
    min_lat = lat_i-1
    min_long = long_i-1
    max_lat = lat_i+1
    max_long = long_i+1

    # ensure we have all necessary tiles loaded
    for lat in min_lat..max_lat do
      for long in min_long..max_long do
        if !AustraliaDem.tile_loaded?(lat, long)
           AustraliaDem.download_tile(lat, long)
           AustraliaDem.load_to_postgis(lat, long)
           AustraliaDem.delete_temp_file(lat, long)
        end
      end
    end

    
    alt_min = elevation - buffer
    alt_max = 5000
    dist_max = 0.01 # degrees
    logger.debug " select val, st_astext(geom) as geom from (select (st_dumpaspolygons(st_reclass(st_union(rast),1,'0-#{alt_min}:0,#{alt_min}-#{alt_max}:1','8BUI'))).* from australia_dem where st_intersects(rast,st_buffer(ST_GeomFromText('POINT(#{point_long} #{point_lat})',4326),#{dist_max}))) as bar where val=1 and st_contains(geom, ST_GeomFromText('POINT(#{point_long} #{point_lat})',4326)); "
    az_poly = AustraliaDem.find_by_sql [" 
       SELECT val, st_astext(ST_MULTI(geom)) as geom 
       FROM (
         SELECT (ST_DUMPASPOLYGONS(
           ST_RECLASS(
             ST_Union(rast),1,'0-#{alt_min}:0,#{alt_min}-#{alt_max}:1','8BUI'
           )
         )).* 
         FROM australia_dem 
         WHERE ST_Intersects(
           rast,
           ST_Buffer(
             ST_SetSRID(ST_MakePoint(#{point_long}, #{point_lat}), 4326),
             #{dist_max}
          )
        )
       ) as bar 
       WHERE val=1 
         AND ST_Intersects(geom, ST_SetSRID(ST_MakePoint(#{point_long}, #{point_lat}), 4326)); "]
    if az_poly && az_poly.count.positive? && az_poly.first['geom']
      boundary = az_poly.first['geom']
    end
    boundary
  end
end
