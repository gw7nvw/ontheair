# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)
#User.create(callsign: "gw7nvw", firstname: "Matt", lastname: "Briggs", email: "mattbriggs@yahoo.com", activated: true, is_active: true, is_admin: true,  is_modifier: true, password: "dummy", password_confirmation: "dummy")

#Projection.create(id: 2193, name: "NZTM2000", proj4: "+proj=tmerc +lat_0=0 +lon_0=173 +k=0.9996 +x_0=1600000 +y_0=10000000 +ellps=GRS80 +towg", wkt: "", epsg: 2193)
#Projection.create(id: 4326, name: "WGS84", proj4: "+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs", wkt: "", epsg: 4326)
#Projection.create(id: 27200, name: "NZMG49", proj4: "+proj=nzmg +lat_0=-41 +lon_0=173 +x_0=2510000 +y_0=6023150 +ellps=intl +datum=nzgd49 +units=m +no_defs", wkt: "", epsg: 27200)
#Projection.create(id: 27291, name: "NIYG", proj4: "+proj=tmerc +lat_0=-39 +lon_0=175.5 +k=1 +x_0=274319.5243848086 +y_0=365759.3658464114 +ellps=intl +datum=nzgd49 +to_meter=0.9143984146160287 +no_defs", wkt: "", epsg: 27291)
#Projection.create(id: 27292, name: "SIYG", proj4: "+proj=tmerc +lat_0=-44 +lon_0=171.5 +k=1 +x_0=457199.2073080143 +y_0=457199.2073080143 +ellps=intl +datum=nzgd49 +to_meter=0.9143984146160287 +no_defs", wkt: "", epsg: 27292)
#Projection.create(id: 900913, name: "GOOGLE", proj4: "+proj=merc +a=6378137 +b=6378137 +lat_ts=0.0 +lon_0=0.0 +x_0=0.0 +y_0=0 +k=1.0 +units=m +nadgrids=@null +no_defs", wkt: "", epsg: 900913)
##Timezone.create(name: "Pacific/Auckland", description: "Pacific / New Zealand / Auckland", difference: 13)
#Timezone.create(name: "UTC", description: "UTC", difference: 0)
#Timezone.create(name: "Pacific/Chatham", description: "Pacific / New Zealand / Chatham Islands", difference: 13.45)

#Maplayer.create(name: "NZTM Topo 2009", baseurl: "http://au.mapspast.org.nz/topo50/", basemap: "mapspast", minzoom: 0, maxzoom: 10, imagetype: "png")
#Maplayer.create(name: "(LINZ) Topo50 latest", baseurl: "http://tiles-a.data-cdn.linz.govt.nz/services;key=d8c83efc690a4de4ab067eadb6ae95e4/tiles/v4/layer=767/EPSG:2193/", basemap: "linz", minzoom: 0, maxzoom: 16, imagetype: "png")
#Maplayer.create(name: "(LINZ) Airphoto latest", baseurl: "http://tiles-a.data-cdn.linz.govt.nz/services;key=d8c83efc690a4de4ab067eadb6ae95e4/tiles/v4/set=2/EPSG:2193/", basemap: "linz", minzoom: 0, maxzoom: 16, imagetype: "png")


#ps=Place.find_by_sql [ "select * from places where place_type='Hut'"]
#ps.each do |p|
#  Hut.create(name: p.name, description: p.description, location: p.location, x: p.x, y: p.y, altitude: p.altitude, is_active: true, routeguides_link: 'http://routeguides.co.nz/places/'+p.id.to_s)
#end

#pull in docparks 
#Park.update_table

#assign huts to parks
#Hut.assign_all_parks

#add links
#Hut.update_links

SotaRegion.create(dxcc: "ZL1", region: "AK")
SotaRegion.create(dxcc: "ZL1", region: "WL")
SotaRegion.create(dxcc: "ZL1", region: "WK")
SotaRegion.create(dxcc: "ZL1", region: "TN")
SotaRegion.create(dxcc: "ZL1", region: "NL")
SotaRegion.create(dxcc: "ZL1", region: "MW")
SotaRegion.create(dxcc: "ZL1", region: "HB")
SotaRegion.create(dxcc: "ZL1", region: "GI")
SotaRegion.create(dxcc: "ZL1", region: "BP")
SotaRegion.create(dxcc: "ZL3", region: "CB")
SotaRegion.create(dxcc: "ZL3", region: "FL")
SotaRegion.create(dxcc: "ZL3", region: "MB")
SotaRegion.create(dxcc: "ZL3", region: "OT")
SotaRegion.create(dxcc: "ZL3", region: "SL")
SotaRegion.create(dxcc: "ZL3", region: "TM")
SotaRegion.create(dxcc: "ZL3", region: "WC")
SotaRegion.create(dxcc: "ZL7", region: "CI")
SotaRegion.create(dxcc: "ZL8", region: "MI")
SotaRegion.create(dxcc: "ZL8", region: "RI")
SotaRegion.create(dxcc: "ZL9", region: "DI")
SotaRegion.create(dxcc: "ZL9", region: "AD")
SotaRegion.create(dxcc: "ZL9", region: "AI")
SotaRegion.create(dxcc: "ZL9", region: "CI")
SotaRegion.create(dxcc: "ZL9", region: "AN")

