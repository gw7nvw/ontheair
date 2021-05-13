class WwffPark < ActiveRecord::Base

  def park
    p=Park.find_by(:id => self.napalis_id)
  end

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
          nid=("998"+self.reference[5..8]).to_i
          p=Park.find_by_id(nid)
          if !p then
            p=Park.new
            p.id=nid
            p.is_mr=false
            p.description="Imported from WWFF"
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

  url = "http://parksnpeaks.org/api/SITES/WWFF"
  data = JSON.parse(open(url).read)
  if data then
    data.each do |feature|
       code=feature["ID"]
       if code and code[0..1]=="ZL" then
         p=WwffPark.new
         p.code=code
         p.name=feature["Name"]
         p.dxcc=feature["State"]
         p.region="OC / ZL"
         p.location='POINT('+feature["Longitude"].to_s+' '+feature["Latitude"].to_s+')'
         p.save
         a=Asset.add_wwff_park(p)
         a.find_links
       end
    end
  end
end

def self.migrate_to_assets
  pps=WwffPark.all
  pps.each do |pp|
    p=Asset.find_by(code: 'ZLP/'+pp.napalis_id.to_s)
    if p then
      dup=AssetLink.where(parent_code: pp.code, child_code: p.code)
      if !dup or dup.count==0 then
        al=AssetLink.create(parent_code: pp.code, child_code: p.code)
      end
      dup=AssetLink.where(parent_code: p.code, child_code: pp.code)
      if !dup or dup.count==0 then
        al=AssetLink.create(parent_code: p.code, child_code: pp.code)
      end
      puts pp.code
    else
      puts "ERROR: no park found for POTA park "+pp.name
    end
  end
end


end
