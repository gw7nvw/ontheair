class PotaPark < ActiveRecord::Base
  belongs_to :park, class_name: "Park"
  belongs_to :island, class_name: "Island"

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

def self.import
  pps=self.all
  pps.each do |pp|
     pp.destroy
  end

  url = "https://api.pota.us/park/grids/-47.5/165/-34/180/0"
  data = JSON.parse(open(url).read)
  if data then
    data["features"].each do |feature|
       properties=feature["properties"]
       p=PotaPark.new
       p.reference=properties["reference"]
       p.name=properties["name"]
       p.location='POINT('+properties["longitude"].to_s+' '+properties["latitude"].to_s+')'
       p.save
       pp=p.find_park
       if !pp then pp=p.find_doc_park end
       if pp then p.park_id=pp.id end
       p.save
    end
  end
end
end
