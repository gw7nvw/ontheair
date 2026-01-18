module MapHelper
  # default map is 3x3 tiles
  # scale is 1:((20037508*2)/256)/2**zoom
  def get_map(gridx, gridy, zoom, id)
    get_map_x_y(gridx, gridy, zoom, 3, 3, id)
  end

  def get_3857_map_x_y(lng_deg, lat_deg, zoom, xsize, ysize, id)
    system("mkdir /tmp/#{id}")
    lat_rad = lat_deg/180 * Math::PI
    n = 2.0 ** zoom
    x = ((lng_deg + 180.0) / 360.0 * n)
    y = ((1.0 - Math::log(Math::tan(lat_rad) + (1 / Math::cos(lat_rad))) / Math::PI) / 2.0 * n)
    int_x = x.to_i
    int_y = y.to_i
    offset_x = 256 * (xsize - 1) / 2 + (x - int_x) * 256
    offset_y = 256 * (ysize - 1) / 2 + (y - int_y) * 256
  
#    tile_server = "https://tile.tracestrack.com/topo__/{z}/{x}/{y}.png?key=874a3238a1d41a597af32a3a6fcdc74e"
#    tile_server = "https://api.maptiler.com/maps/outdoor-v4/256/{z}/{x}/{y}.png?key=yXodNjKS8PzfQcTJ4N1G"
    tile_server = "https://tile.openstreetmap.org/{z}/{x}/{y}.png"
    # 9 tiles, one in each direction around centre
    minx = int_x - (xsize - 1) / 2
    maxx = int_x + (xsize - 1) / 2
    miny = int_y - (ysize - 1) / 2
    maxy = int_y + (ysize - 1) / 2

    puts int_x, minx, maxx
    puts int_y, miny, maxy
    # download all the tiles
    for x in minx..maxx do
      for y in miny..maxy do
        download_tile(x, y, zoom, tile_server, id, false)
      end
    end

    # concatenate tiles into one image
    system("montage /tmp/#{id}/#{zoom}*.png -mode Concatenate -tile #{xsize}x#{ysize} /tmp/#{id}.jpg")
    # add the dot, diameter 6 pixels
    system("convert /tmp/#{id}.jpg -fill blue -stroke red -draw 'circle #{offset_x},#{offset_y} #{offset_x + 6},#{offset_y + 6}' -quality 45 /tmp/#{id}-point.jpg")
    system("rm -r /tmp/#{id}") #remove temporary files
    system("rm -r /tmp/#{id}.jpg") #remove temporary files

    # return the filename of map image created
    "/tmp/#{id}-point.jpg"
  end

  # read map tiles from a ZXY tilestack for given location and zoom
  # concatenate them into a single jpg
  # add a 'You are here' point
  # return path+filename to the file
  #
  # Assumes an XYZ tile server in EPSG:2193 (NZTM) projection
  # You'd need to tweak the maths to use one in google's web_mercator projection such as  openstreetmap
  def get_map_x_y(gridx, gridy, z, xsize, ysize, id)
    # X,Y coordinates for centre tile at this zoom level
    c_x = ((gridx + 20037508) / (4891.97 * 2**(13 - z))).to_i
    c_y = ((gridy + 20037508) / (4891.97 * 2**(13 - z))).to_i
    system("mkdir /tmp/#{id}")
#    tile_server = 'http://s3-ap-southeast-2.amazonaws.com/au.mapspast.org.nz/topo50-2019/{z}/{x}/{y}.png'
    tile_server='https://object-storage.nz-por-1.catalystcloud.io/v1/AUTH_b1d1ad52024f4f1b909bfea0e41fbff8/mapspast/2193/topo50-2019/{z}/{x}/{y}.png'
    # 9 tiles, one in each direction around centre
    minx = c_x - (xsize - 1) / 2
    maxx = c_x + (xsize - 1) / 2
    miny = c_y - (ysize - 1) / 2
    maxy = c_y + (ysize - 1) / 2

    # download all the tiles
    for x in minx..maxx do
      for y in miny..maxy do
        download_tile(x, y, z, tile_server, id)
      end
    end

    # calculate the col,row position of the 'you are here' on the combined jpg
    lx = maxx * (4891.97 * 2**(13 - z)) - 20037508 # left border x grid ref of map image
    by = maxy * (4891.97 * 2**(13 - z)) - 20037508 # bottom border y grid ref of map image
    dx = lx - gridx # meters of our dot from left border
    dy = by - gridy # meters of our dot from bottom border
    sx = (dx / (4891.97 * 2**(13 - z))) * 256 # convert x position to pixels
    sy = (dy / (4891.97 * 2**(13 - z))) * 256 # convert y position to pixels
    px = 512 - sx # apply direction / offset used in 'convert'
    py = 256 + sy # apply direction / offset used in 'convert'
    # concatenate tiles into one image
    system("montage /tmp/#{id}/#{z}*.png -mode Concatenate -tile #{xsize}x#{ysize} /tmp/#{id}.jpg")
    # add the dot, diameter 6 pixels
    system("convert /tmp/#{id}.jpg -fill blue -stroke red -draw 'circle #{px},#{py} #{px + 6},#{py + 6}' -quality 45 /tmp/#{id}-point.jpg")
    # system("rm -r /tmp/#{id}") #remove temporary files

    # return the filename of map image created
    "/tmp/#{id}-point.jpg"
  end

  # a montage of 256x256 tiles at a range of zoom levels rather than a single map.
  # not used
  def get_map_zoomed(gridx, gridy, min_zoom, max_zoom, id)
    system("mkdir /tmp/#{id}")
    #tile_server = 'http://s3-ap-southeast-2.amazonaws.com/au.mapspast.org.nz/topo50-2019/{z}/{x}/{y}.png'
    tile_server='https://object-storage.nz-por-1.catalystcloud.io/v1/AUTH_b1d1ad52024f4f1b909bfea0e41fbff8/mapspast/2193/topo50-2019/{z}/{x}/{y}.png'
    (min_zoom..max_zoom).step(2).each do |z|
      x = ((gridx + 19740000) / (2.356 * 2**(24 - z)))
      y = ((gridy + 19680000) / (2.356 * 2**(24 - z)))
      download_tile(x.to_i, y.to_i, z, tile_server, id)
    end
    system("montage /tmp/#{id}/*.png -mode Concatenate -tile #{max_zoom - min_zoom}x /tmp/#{id}.jpg")
    system("rm -r /tmp/#{id}")
    "/tmp/#{id}.jpg"
  end

  # Download an individual map tile
  def download_tile(x, y, z, tile_server, id, reverse = true)
    begin
      # fill in reqired x, y, z to URL
      url = tile_server.gsub('{x}', x.to_s).gsub('{y}', y.to_s).gsub('{z}', z.to_s)
      if reverse then 
        filename = '/tmp/' + id + '/' + z.to_s + '_' + (9999 - y).to_s + '_' + x.to_s
      else
        filename = '/tmp/' + id + '/' + z.to_s + '_' + y.to_s + '_' + x.to_s
      end
      puts url, filename

      # download tile
      f = File.open(filename + '.png', 'wb') do |file|
        file.write(open(url, "Referer" => "https://ontheair.nz", "User-Agent" => "ontheair",).read)
      end

    # if we fail to download a tile (happens with bad grid ref or outside NZ)
    # infill with a blank tile
    rescue
      unless f.nil?
        f.close unless f.closed?
      end
      system("cp /var/www/html/hota/public/assets/blank.png #{filename}.png")
    end

    # return path to downloaded tile
    filename
  end

  def transform_geom(x,y,srs,trs)
    # convert to WGS84 (EPSG4326) for database
    fromproj4s = Projection.find_by_id(srs).proj4
    toproj4s = Projection.find_by_id(trs).proj4

    fromproj = RGeo::CoordSys::Proj4.new(fromproj4s)
    toproj = RGeo::CoordSys::Proj4.new(toproj4s)

    xyarr = RGeo::CoordSys::Proj4.transform_coords(fromproj, toproj, x.to_f, y.to_f)
  end


  def transform_geom(x,y,srs,trs)
    # convert to WGS84 (EPSG4326) for database
    fromproj4s = Projection.find_by_id(srs).proj4
    toproj4s = Projection.find_by_id(trs).proj4

    fromproj = RGeo::CoordSys::Proj4.new(fromproj4s)
    toproj = RGeo::CoordSys::Proj4.new(toproj4s)

    xyarr = RGeo::CoordSys::Proj4.transform_coords(fromproj, toproj, x.to_f, y.to_f)
  end


  def transform_geom(x,y,srs,trs)
    # convert to WGS84 (EPSG4326) for database
    fromproj4s = Projection.find_by_id(srs).proj4
    toproj4s = Projection.find_by_id(trs).proj4

    fromproj = RGeo::CoordSys::Proj4.new(fromproj4s)
    toproj = RGeo::CoordSys::Proj4.new(toproj4s)

    xyarr = RGeo::CoordSys::Proj4.transform_coords(fromproj, toproj, x.to_f, y.to_f)
  end

end
