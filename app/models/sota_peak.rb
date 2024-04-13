class SotaPeak < ActiveRecord::Base
  belongs_to :park, class_name: "Park"
  belongs_to :island, class_name: "Island"

def codename
  codename=self.summit_code+" - "+self.name
end

def x
       # convert to 2193 
       fromproj4s= Projection.find_by_id(4326).proj4
       toproj4s=  Projection.find_by_id(2193).proj4

       fromproj=RGeo::CoordSys::Proj4.new(fromproj4s)
       toproj=RGeo::CoordSys::Proj4.new(toproj4s)

       xyarr=RGeo::CoordSys::Proj4::transform_coords(fromproj,toproj,self.location.x,self.location.y)
       xyarr[0]
end


def y
       # convert to 2193 
       fromproj4s= Projection.find_by_id(4326).proj4
       toproj4s=  Projection.find_by_id(2193).proj4

       fromproj=RGeo::CoordSys::Proj4.new(fromproj4s)
       toproj=RGeo::CoordSys::Proj4.new(toproj4s)

       xyarr=RGeo::CoordSys::Proj4::transform_coords(fromproj,toproj,self.location.x,self.location.y)
       xyarr[1]
end


def find_doc_park
   #ps=Docparks.find_by_sql [ %q{select * from docparks dp where ST_Within(ST_GeomFromText('}+self.location.as_text+%q{', 4326), dp."WKT");} ]
   ps=Crownparks.find_by_sql [ %q{select * from crownparks dp where ST_Within(ST_GeomFromText('}+self.location.as_text+%q{', 4326), dp."WKT");} ]
   if ps and ps.first then
      Park.find_by_id(ps.first.id)
    else nil end
end

def find_park
   ps=Park.find_by_sql [ %q{select * from parks p where ST_Within(ST_GeomFromText('}+self.location.as_text+%q{', 4326), p.boundary);} ]
   if ps then ps.first else nil end
end

def find_island
   ps=IslandPolygon.find_by_sql [ %q{select * from island_polygons p where ST_Within(ST_GeomFromText('}+self.location.as_text+%q{', 4326), p."WKT");} ]
   if ps then ps.first else nil end
end


def self.import

  sps=self.all
  sps.each do |sp|
     sp.destroy
  end

  srs=SotaRegion.all
  srs.each do |sr|
    url = "https://api2.sota.org.uk/api/regions/"+sr.dxcc+"/"+sr.region+"?client=sotawatch&user=anon"
    data = JSON.parse(open(url).read)
    if data then
      summits=data["summits"]
      if summits then summits.each do |s|
        ss=SotaPeak.new
        ss.summit_code=s["summitCode"]
        ss.name=s["name"]
        ss.short_code=s["shortCode"]
        ss.valid_to=s["validTo"]
        ss.valid_from=s["validFrom"]
        ss.alt=s["altM"]
        ss.location="POINT("+s["longitude"].to_s+" "+s["latitude"].to_s+")"
        ss.points=s["points"]

        ss.save
        a=Asset.add_sota_peak(ss)
        a.add_links
      end end
   end
  end 
end
end
