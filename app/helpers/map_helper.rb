module MapHelper

def get_map(gridx, gridy, zoom, id)
  scale=((20037508*2)/256)/2**zoom
  filename=get_map_x_y(gridx,gridy,zoom,3,3, id)
end

def get_map_x_y(gridx,gridy,z,xsize,ysize,id)
  c_x=((gridx+20037508)/((4891.97)*2**(13-z))).to_i
  c_y=((gridy+20037508)/((4891.97)*2**(13-z))).to_i
  system("mkdir /tmp/#{id}")
  tile_server = "http://s3-ap-southeast-2.amazonaws.com/au.mapspast.org.nz/topo50-2019/{z}/{x}/{y}.png"
  minx=c_x-(xsize-1)/2
  maxx=c_x+(xsize-1)/2
  miny=c_y-(ysize-1)/2
  maxy=c_y+(ysize-1)/2

  for x in minx..maxx do
    for y in miny..maxy do
      png_path=download_tile(x,y,z,tile_server,id)
    end
  end
  lx=x*((4891.97)*2**(13-z))-20037508
  by=y*((4891.97)*2**(13-z))-20037508
  puts lx.to_s+" "+by.to_s
  dx=lx-gridx
  dy=by-gridy
  puts dx.to_s+" "+dy.to_s
  sx=(dx/(4891.97*2**(13-z)))*256
  sy=(dy/(4891.97*2**(13-z)))*256
  puts sx.to_s+" "+sy.to_s
  px=512-sx
  py=256+sy
  puts px.to_s+" "+py.to_s
  system("montage /tmp/#{id}/#{z}*.png -mode Concatenate -tile #{xsize}x#{ysize} /tmp/#{id}.jpg")
  system("convert /tmp/#{id}.jpg -fill blue -stroke red -draw 'circle #{px},#{py} #{px+6},#{py+6}' -quality 45 /tmp/#{id}-point.jpg")
#  system("rm -r /tmp/#{id}")
  "/tmp/#{id}-point.jpg"
end

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

def download_tile(x,y,z,tile_server,id)
   begin
   url=tile_server.gsub("{x}",x.to_s).gsub("{y}",y.to_s).gsub("{z}",z.to_s)
   filename="/tmp/"+id+"/"+z.to_s+"_"+(9999-y).to_s+"_"+x.to_s
   f=File.open(filename+".png", "wb") do |file|
     file.write(open(url).read)
   end
   rescue
     if !f.nil? then 
       f.close unless f.closed? 
     end
     system("cp /var/www/html/hota/public/assets/blank.png #{filename}.png")
   end
   filename
end


end
