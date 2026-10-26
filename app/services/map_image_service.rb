require 'mini_magick'

class MapImageService
  def generate_3857_matrix(lng_deg, lat_deg, zoom, xsize, ysize)
    lat_rad = lat_deg/180 * Math::PI
    n = 2.0 ** zoom
    x = ((lng_deg + 180.0) / 360.0 * n)
    y = ((1.0 - Math.log(Math.tan(lat_rad) + (1 / Math.cos(lat_rad))) / Math::PI) / 2.0 * n)
    int_x = x.to_i
    int_y = y.to_i
    offset_x = 256 * (xsize - 1) / 2 + (x - int_x) * 256
    offset_y = 256 * (ysize - 1) / 2 + (y - int_y) * 256

    tile_server = "https://tile.openstreetmap.org/{z}/{x}/{y}.png"
    # 9 tiles, one in each direction around centre
    minx = int_x - (xsize - 1) / 2
    maxx = int_x + (xsize - 1) / 2
    miny = int_y - (ysize - 1) / 2
    maxy = int_y + (ysize - 1) / 2

    puts int_x, minx, maxx
    puts int_y, miny, maxy

    return matrix_tiles(xsize, ysize, minx, miny, maxx, maxy, offset_x, offset_y, tile_server, false)
  end

  def generate_2193_matrix(gridx, gridy, z, xsize, ysize)
    logger.error("THERE")
    # X,Y coordinates for centre tile at this zoom level
    c_x = ((gridx + 20037508) / (4891.97 * 2**(13 - z))).to_i
    c_y = ((gridy + 20037508) / (4891.97 * 2**(13 - z))).to_i
    #    tile_server = 'http://s3-ap-southeast-2.amazonaws.com/au.mapspast.org.nz/topo50-2019/{z}/{x}/{y}.png'
    tile_server="https://object-storage.nz-por-1.catalystcloud.io/v1/AUTH_b1d1ad52024f4f1b909bfea0e41fbff8/mapspast/2193/topo50-2019/{z}/{x}/{y}.png"
    # 9 tiles, one in each direction around centre
    minx = c_x - (xsize - 1) / 2
    maxx = c_x + (xsize - 1) / 2
    miny = c_y - (ysize - 1) / 2
    maxy = c_y + (ysize - 1) / 2

    # calculate the col,row position of the 'you are here' on the combined jpg
    lx = maxx * (4891.97 * 2**(13 - z)) - 20037508 # left border x grid ref of map image
    by = maxy * (4891.97 * 2**(13 - z)) - 20037508 # bottom border y grid ref of map image
    dx = lx - gridx # meters of our dot from left border
    dy = by - gridy # meters of our dot from bottom border
    sx = (dx / (4891.97 * 2**(13 - z))) * 256 # convert x position to pixels
    sy = (dy / (4891.97 * 2**(13 - z))) * 256 # convert y position to pixels
    offset_x = 512 - sx # apply direction / offset used in 'convert'
    offset_y = 256 + sy # apply direction / offset used in 'convert'

    return matrix_tiles(xsize, ysize, minx, miny, maxx, maxy, offset_x, offset_y, tile_server, true)
  end

  private
  
  def download_tile(x, y, z, tile_server, id)
    # fill in reqired x, y, z to URL
    url = tile_server.gsub("{x}", x.to_s).gsub("{y}", y.to_s).gsub("{z}", z.to_s)

    # download tile
    # Open the local file for binary writing as before
    begin
      # Use URI.open explicitly and pass headers as a standard Ruby 3 options hash
      remote_data = URI.open(
        url,
        "Referer" => "http://new.ontheair.nz",
        "User-Agent" => "ontheair"
      ).read

    rescue
      remote_data = blank_tile()
    end

    # return path to downloaded tile
    remote_data
  end

  def blank_tile
    blank_tile_blob = MiniMagick::Image.create("jpeg") do |c|
      c.size "256x256"
      c.canvas "white"
    end.to_blob
  end

  def matrix_tiles(xsize, ysize, minx, miny, maxx, maxy, offset_x, offset_y, tile_server, reverse=true)
    y_iterator = reverse ? (miny..maxy).reverse_each : (miny..maxy).each

    # 2. Combine the map tiles into a unified layout canvas
    montage = MiniMagick::Tool::Montage.new do |m|
      (minx..maxx).each do |x|
        y_iterator.call do |y|
          m << download_tile(x, y, z, tile_server)
        end
      end

      m.mode "Concatenate"
      m.tile "#{xsize}x#{ysize}"
      m.quality quality
      m << "jpeg:-" # Pipes the resulting binary stream directly to memory
    end

    # 3. Read the combined binary stream
    combined_image = MiniMagick::Image.read(montage)

    # 4. Draw the activator position marker
    combined_image.combine_options do |c|
      c.fill "blue"
      c.stroke "red"
      c.draw "circle #{offset_x},#{offset_y} #{offset_x + 6},#{offset_y + 6}"
    end

    combined_image.to_blob
  rescue StandardError => e
    Rails.logger.error "MapImageService failed: #{e.message}"
    nil
  end
end
