class PotaPark < ActiveRecord::Base
  belongs_to :park, class_name: "Park"
  belongs_to :island, class_name: "Island"

  def find_doc_park
   #ps=Docparks.find_by_sql [ %q{select * from docparks dp where ST_Within(ST_GeomFromText('}+self.location.as_text+%q{', 4326), dp."WKT");} ]
   ps=Asset.find_by_sql [ %q{select * from assets dp where ST_Within(ST_GeomFromText('}+self.location.as_text+%q{', 4326), dp.boundary) and asset_type='park';} ]
   if !ps or ps.count==0 then
      puts "Trying for nearest"
     ps=Asset.find_by_sql [ %q{ SELECT * 
       FROM assets dp
       WHERE ST_DWithin(boundary, ST_GeomFromText('}+self.location.as_text+%q{', 4326), 10000, false) and asset_type='park' 
       ORDER BY ST_Distance(boundary, ST_GeomFromText('}+self.location.as_text+%q{', 4326)) LIMIT 50; } ]
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
          p=Asset.find_by(code: "ZLP/"+nid.to_s)
          if !p then 
            p=Asset.new
            p.code="ZLP/"+nid.to_s
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
      puts "Found doc park "+ps.first.code+" : "+ps.first.name+" == "+self.name
      Asset.find_by(code: ps.first.code)
   end
  end

def self.import

  urls=["https://api.pota.app/park/grids/-47.5/165/-40/180/0", "https://api.pota.app/park/grids/-40/165/-34/180/0", "https://api.pota.app/park/grids/-55.0/165/-47.5/180/0", "https://api.pota.app/park/grids/-45/-178/-42/-175/0"]
  urls.each do |url|
    data = JSON.parse(open(url).read)
    if data then
      puts "Found "+data["features"].count.to_s+" parks"
      data["features"].each do |feature|
         is_invalid=false
         properties=feature["properties"]
         puts properties.to_json
         p=PotaPark.find_by(reference: properties["reference"])
         new=false
         if !p then 
           p=PotaPark.new
           new=true
           puts "New park"
         end
         p.reference=properties["reference"]
         puts p.reference
         p.name=properties["name"]
         puts p.name
         #p.location='POINT('+properties["longitude"].to_s+' '+properties["latitude"].to_s+')'
         if new==true or p.location == nil then
           #try to match against park
           searchname=p.name.gsub("'","''")
           zps=Asset.find_by_sql [" select id, name, code, asset_type, location from assets where asset_type='park' and name='#{searchname}' and is_active=true" ]
           id=[""]
           if !zps or zps.count==0 then
             #look for best name match
             short_name=searchname
             short_name=short_name.gsub("Forest","")
             short_name=short_name.gsub("Regional","")
             short_name=short_name.gsub("Conservation","")
             short_name=short_name.gsub("Park","")
             short_name=short_name.gsub("Area","")
             short_name=short_name.gsub("Scenic","")
             short_name=short_name.gsub("Reserve","")
             short_name=short_name.gsub("Marine","")
             short_name=short_name.gsub("Wildlife","")
             short_name=short_name.gsub("Ecological","")
             short_name=short_name.gsub("National","")
             short_name=short_name.gsub("Wilderness","")
             short_name=short_name.gsub("Te","")
             short_name=short_name.gsub("  "," ")
             puts "no exact match, try like: "+short_name
             zps=Asset.find_by_sql [" select id, name, code, asset_type, location from assets where asset_type='park' and name ilike '%%#{short_name.strip}%%' and is_active=true" ]
           end
           if zps and zps.count>1 then
                 puts "==========================================================="
                 count=0
                 zps.each do |p|
                   puts count.to_s+" - "+p.name+" - "+p.code+" == "+self.name
                   count+=1
                 end
                 puts "Select match (or 'a' to skip):"
                 id=gets
                 if id and id.length>1 and id[0]!="a" then zps=[zps[id.to_i]] end
           end

           if !zps or zps.count==0 or id[0]=="a" then
             puts "enter asset id to match: "
             code=gets
             zps=Asset.where(code: code.strip)
           end

           if zps and zps.count==1 then
             park=zps.first
             p.location=park.location
             puts "Matched #{p.name} with #{park.name}"
           else
             puts "Could not find match. No location"
             is_invalid=true
           end
         else
           puts "Existing POTA park"
         end

         if is_invalid==false then
           p.save
           a=Asset.add_pota_park(p, park)
           if new then
             a.add_region
             a.add_area
             a.add_links
           end
         end
      end
    end
  end
end
 
def self.migrate_to_assets
  pps=PotaPark.all
  pps.each do |pp|
    p=Asset.find_by(code: 'ZLP/'+pp.park_id.to_s)
    if p then  
      dup=AssetLink.where(contained_code: pp.reference, containing_code: p.code)
      if !dup or dup.count==0 then
        al=AssetLink.create(contained_code: pp.reference, containing_code: p.code)
      end
      dup=AssetLink.where(contained_code: p.code, containing_code: pp.reference)
      if !dup or dup.count==0 then
        al=AssetLink.create(contained_code: p.code, containing_code: pp.reference)
      end
      puts pp.reference
    else
      puts "ERROR: no park found for POTA park "+pp.name
    end 
  end
end

def self.add_boundaries_from_assets
  pps=Asset.find_by_sql [ " select id,name,code from assets where asset_type='pota park'  and boundary is null order by name; " ]
  pps.each do |pp|
       puts "Updating "+pp.name
       als=AssetLink.where(contained_code: pp.code)
       al=nil
       if als.count>0 then
         if als.count>1 then
           count=0
           validcount=0
           lastvalid=nil
           als.each do 
              if als[count].child.asset_type=="park" and als[count].child.is_active=true then
                puts count.to_s+": "+als[count].child.name
                validcount+=1
                lastvalid=count 
              end
              count+=1
           end
           if validcount>1 then
             puts "Please select park or 'C'ancel:"
             select=gets.chomp
             if select!='C' then al=als[select.to_i] else al=nil end
           elsif validcount==1 then
             al=als[lastvalid]
           else
             al=nil
           end
             
         else
           al=als.first
         end
         if al then
           puts "... from "+al.child.name
           ActiveRecord::Base.connection.execute("update assets set boundary=(select boundary from assets where id="+al.child.id.to_s+") where id="+pp.id.to_s+";")
           #puts "update assets set boundary=select(boundary from assets where id="+al.child.id.to_s+") where id="+pp.id.to_s+";"
         end
       end

  end
end

def self.add_regions
  pps=Asset.find_by_sql [ " select id,region,location,name,code from assets where asset_type='pota park'  order by name; " ]
  pps.each do |pp|
    puts pp.name
    pp.add_region
  end   
end

def self.add_pota_links
  pps=Asset.find_by_sql [ " select id,name,code from assets where asset_type='pota park'  order by name; " ]
  pps.each do |pp|
    puts pp.name
    pp.add_links
  end   
end
end

