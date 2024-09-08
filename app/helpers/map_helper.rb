module MapHelper

#default map is 3x3 tiles
#scale is 1:((20037508*2)/256)/2**zoom
def get_map(gridx, gridy, zoom, id)
  filename=get_map_x_y(gridx,gridy,zoom,3,3, id)
end

# read map tiles from a ZXY tilestack for given location and zoom
# concatenate them into a single jpg
# add a 'You are here' point
# return path+filename to the file
#
#Assumes an XYZ tile server in EPSG:2193 (NZTM) projection
#You'd need to tweak the maths to use one in google's web_mercator projection such as openstreetmap
def get_map_x_y(gridx,gridy,z,xsize,ysize,id)
  #X,Y coordinates for centre tile at this zoom level
  c_x=((gridx+20037508)/((4891.97)*2**(13-z))).to_i
  c_y=((gridy+20037508)/((4891.97)*2**(13-z))).to_i
  system("mkdir /tmp/#{id}")
  tile_server = "http://s3-ap-southeast-2.amazonaws.com/au.mapspast.org.nz/topo50-2019/{z}/{x}/{y}.png"

  #9 tiles, one in each direction around centre
  minx=c_x-(xsize-1)/2
  maxx=c_x+(xsize-1)/2
  miny=c_y-(ysize-1)/2
  maxy=c_y+(ysize-1)/2

  #download all the tiles
  for x in minx..maxx do
    for y in miny..maxy do
      png_path=download_tile(x,y,z,tile_server,id)
    end
  end

  #calculate the col,row position of the 'you are here' on the combined jpg
  lx=x*((4891.97)*2**(13-z))-20037508 #left border x grid ref of map image
  by=y*((4891.97)*2**(13-z))-20037508 #bottom border y grid ref of map image
  dx=lx-gridx #meters of our dot from left border
  dy=by-gridy #meters of our dot from bottom border
  sx=(dx/(4891.97*2**(13-z)))*256 #convert x position to pixels
  sy=(dy/(4891.97*2**(13-z)))*256 #convert y position to pixels
  px=512-sx #apply direction / offset used in 'convert'
  py=256+sy #apply direction / offset used in 'convert'
  #concatenate tiles into one image
  system("montage /tmp/#{id}/#{z}*.png -mode Concatenate -tile #{xsize}x#{ysize} /tmp/#{id}.jpg")
  #add the dot, diameter 6 pixels
  system("convert /tmp/#{id}.jpg -fill blue -stroke red -draw 'circle #{px},#{py} #{px+6},#{py+6}' -quality 45 /tmp/#{id}-point.jpg")
#  system("rm -r /tmp/#{id}") #remove temporary files

  #return the filename of map image created
  "/tmp/#{id}-point.jpg"
end

#a montage of 256x256 tiles at a range of zoom levels rather than a single map. 
#not used
def get_map_zoomed(gridx,gridy,min_zoom,max_zoom,id)
  system("mkdir /tmp/#{id}")
  tile_server = "http://s3-ap-southeast-2.amazonaws.com/au.mapspast.org.nz/topo50-2019/{z}/{x}/{y}.png"
  (min_zoom..max_zoom).step(2).each do |z| 
      x=((gridx+19740000)/(2.356*2**(24-z)))
      y=((gridy+19680000)/(2.356*2**(24-z)))
      png_path=download_tile(x.to_i,y.to_i,z,tile_server,id)
  end
  system("montage /tmp/#{id}/*.png -mode Concatenate -tile #{max_zoom-min_zoom}x /tmp/#{id}.jpg")
  system("rm -r /tmp/#{id}")
  "/tmp/#{id}.jpg"
end

#Download an individual map tile.  
def download_tile(x,y,z,tile_server,id)
   begin
   #fill in reqired x,y,z to URL
   url=tile_server.gsub("{x}",x.to_s).gsub("{y}",y.to_s).gsub("{z}",z.to_s)
   filename="/tmp/"+id+"/"+z.to_s+"_"+(9999-y).to_s+"_"+x.to_s

   #download tile
   f=File.open(filename+".png", "wb") do |file|
     file.write(open(url).read)
   end

   #if we fail to download a tile (happens with bad grid ref or outside NZ) 
   #infill with a blank tile
   rescue
     if !f.nil? then 
       f.close unless f.closed? 
     end
     system("cp /var/www/html/hota/public/assets/blank.png #{filename}.png")
   end

   #return path to downloaded tile
   filename
end


end
