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
  pps=self.all
  pps.each do |pp|
     pp.destroy
  end

  urls=["https://api.pota.us/park/grids/-47.5/165/-40/180/0", "https://api.pota.us/park/grids/-40/165/-34/180/0"]
  urls.each do |url|
    data = JSON.parse(open(url).read)
    if data then
      data["features"].each do |feature|
         properties=feature["properties"]
         p=PotaPark.new
         p.reference=properties["reference"]
         puts p.reference
         p.name=properties["name"]
         p.location='POINT('+properties["longitude"].to_s+' '+properties["latitude"].to_s+')'
         p.save
         a=Asset.add_pota_park(p)
         a.add_links
      end
    end
  end
end
 
def self.migrate_to_assets
  pps=PotaPark.all
  pps.each do |pp|
    p=Asset.find_by(code: 'ZLP/'+pp.park_id.to_s)
    if p then  
      dup=AssetLink.where(parent_code: pp.reference, child_code: p.code)
      if !dup or dup.count==0 then
        al=AssetLink.create(parent_code: pp.reference, child_code: p.code)
      end
      dup=AssetLink.where(parent_code: p.code, child_code: pp.reference)
      if !dup or dup.count==0 then
        al=AssetLink.create(parent_code: p.code, child_code: pp.reference)
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
       als=AssetLink.where(parent_code: pp.code)
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

