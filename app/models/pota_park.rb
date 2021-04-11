class PotaPark < ActiveRecord::Base
  belongs_to :park, class_name: "Park"
  belongs_to :island, class_name: "Island"

  def find_doc_park
   #ps=Docparks.find_by_sql [ %q{select * from docparks dp where ST_Within(ST_GeomFromText('}+self.location.as_text+%q{', 4326), dp."WKT");} ]
   ps=Crownparks.find_by_sql [ %q{select * from crownparks dp where ST_Within(ST_GeomFromText('}+self.location.as_text+%q{', 4326), dp."WKT");} ]
   if !ps or ps.count==0 then
      puts "Trying for nearest"
     ps=Crownparks.find_by_sql [ %q{ SELECT * 
       FROM crownparks dp
       WHERE ST_DWithin("WKT", ST_GeomFromText('}+self.location.as_text+%q{', 4326), 10000, false) 
       ORDER BY ST_Distance("WKT", ST_GeomFromText('}+self.location.as_text+%q{', 4326)) LIMIT 50; } ]
   end

   if ps and ps.count>1 then
       puts "==========================================================="
       count=0
       ps.each do |p|
         puts count.to_s+" - "+p.name+" == "+self.name
         count+=1
       end
       puts "Select match (or 'a' to add):"
       id=gets
       if id and id.length>1 and id[0]!="a" then ps=[ps[id.to_i]] else 
        if id[0]=="a" then
          nid=("999"+self.reference[3..6]).to_i
          p=Park.find_by_id(nid)
          if !p then 
            p=Park.new
            p.id=nid
            p.is_mr=false
            p.description="Imported from POTA"
          end
          p.name=self.name
          p.location=self.location
          p.save
          ps=[p.reload]
        else
          ps=nil 
        end
       end
   end
       
   if !ps or ps.count==0 then
      puts "Error: FAILED"
      nil
   elsif id and id[0]=="a" then
      ps[0]
   else
      puts "Found doc park "+ps.first.napalis_id.to_s+" : "+ps.first.name+" == "+self.name
      Park.find_by_id(ps.first.napalis_id)
   end
  end

  def find_park
   ps=Park.find_by_sql [ %q{select * from parks dp where ST_Within(ST_GeomFromText('}+self.location.as_text+%q{', 4326), dp.boundary);} ]
   if !ps or ps.count==0 then
     ps=Park.where('name ILIKE ?',self.name)
   end 
   if !ps or ps.count==0 then
     ps=Park.find_by_sql [ %q{ SELECT * 
       FROM parks dp
       WHERE ST_DWithin(boundary, ST_GeomFromText('}+self.location.as_text+%q{', 4326), 10000, false) 
       ORDER BY ST_Distance(boundary, ST_GeomFromText('}+self.location.as_text+%q{', 4326)) LIMIT 50; } ]
     if ps and ps.count>0 then 
       puts "==========================================================="
       count=0
       ps.each do |p|
         puts count.to_s+" - "+p.name+" == "+self.name
         count+=1
       end
       puts "Select match:"
       gets id
       if id and id.length>1 then ps=[ps[id]] else ps=nil end
     end
   end
   if ps and ps.count>0 then puts "Found park "+ps.first.id.to_s+" : "+ps.first.name+" == "+self.name ; ps.first else nil end
  end

def self.import
  pps=self.all
  pps.each do |pp|
     pp.destroy
  end

  url = "https://api.pota.us/park/grids/-47.5/165/-40/180/0"
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
  url = "https://api.pota.us/park/grids/-40/165/-34/180/0"
  data = JSON.parse(open(url).read)
  if data then
    data["features"].each do |feature|
       properties=feature["properties"]
       dup=PotaPark.where(:reference => properties["reference"])
       if !dup or dup.count<1 then
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
end
