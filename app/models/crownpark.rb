class Crownpark < ActiveRecord::Base
require 'csv'

# To load new doc parks layer
# add 'id column tio eaxch row
# change POLYGON (( to MULTIPOLYGON ((( and ))" to )))"
# # change row titrles to id, Overlays: nil, NaPALIS_ID: nil, End_Date: nil, Vested: nil, Section: nil, Classified: nil, Legislatio: nil, Recorded_A: nil, Conservati: nil, Control_Ma: nil, Government: nil, Private_Ow: nil, Local_Purp: nil, Type: nil, Start_Date: nil, Name: nil, WKT: nil

# in psql delete old database: delete from docparks;
# rails c production
# Crownparks.my_import(filename.csv)
# update crownparks set ctrl_mg_vst=NULL where ctrl_mg_vst='NULL'
# Park.update_table

    #establish_connection "crownparks"

def self.ecan_import(file)
  h=[]
  CSV.foreach(file, :headers => true) do |row|
    h.push(row.to_hash)
  end
 
  h.each do |park|
  p=Crownparks.new
  p.name=park["COMMON_NAM"]
  p.WKT=park["WKT"]
  p.reserve_type="Regional park"
  p.start_date=park["DATE_CREAT"]
  p.recorded_area=park["Shape_Area"].to_d/10000
  p.save
  puts "Added crownpark :"+p.id.to_s+" - "+p.name
  end
end

def self.my_import(file)
  count=0
  CSV.foreach(file, :headers => true) do |row|
    h=row.to_hash
    h.shift
    self.create!(h)
    puts count
    count+=1
  end
end


def self.merge_nearby
#  ActiveRecord::Base.connection.execute("update crownparks set master_id=id where master_id is null;")
  count=0
  hundreds=0
  conn=Crownpark.get_custom_connection("cps",'crownparks','mbriggs','littledog')
  ls=Crownpark.where(is_active: true)
  ls.each do |l|
     l.reload
     count+=1
    if l.is_active and l.name and l.name.length>0  then
      if count>=100 then
         count=0
         hundreds+=1
         puts "Count: "+(hundreds*100).to_s
      end

      ls=Crownpark.find_by_sql [ %q{ SELECT cp2.id from crownparks cp1 
       inner join crownparks cp2
       ON cp2.is_active=true and (cp2.name = cp1.name) and cp2.id != cp1.id and ST_DWithin(cp1."WKT",cp2."WKT", 1, false) 
       where cp1.id= }+l.id.to_s+%q{;} ]
       

      if ls and ls.count>0 then
        #print '#'; $stdout.flush
        comb=nil
        ids=ls.map{ |l2| l2.id }.join(',')
        ids=ids+","+l.id.to_s
        puts ids
        ids.split(',').each do |l2|
          areas=Crownpark.find_by_sql [ %q{ select ST_Area("WKT") as id from crownparks where id in (}+l2+%q{); } ]
          puts "Areas before merge: "+areas.first.id.to_s
        end

        ls.each do |ll|
          l2=Crownpark.find_by_id(ll) 
          l2.is_active=false
          l2.master_id=l.id;
          l2.save
          puts "Merged and deleted "+(l2.name||"unnamed")+" "+l2.id.to_s+" as duplicate of "+(l.name||"unnamed")+l.id.to_s
        end
        conn.execute(%q{update crownparks set "WKT"=(select st_multi(ST_CollectionExtract(st_collect("WKT"),3)) as "WKT" from crownparks where id in (}+ids+%q{)) where id=}+l.id.to_s+%q{; } )

        areas=Crownpark.find_by_sql [ %q{ select ST_Area("WKT") as id from crownparks where id in (}+l.id.to_s+%q{); } ]
        puts "Area after merge: "+areas.first.id.to_s
      end
    end

  end
  true
end

private

 def self.get_custom_connection(identifier, dbname, dbuser, password)
      eval("Custom_#{identifier} = Class::new(ActiveRecord::Base)")
      eval("Custom_#{identifier}.establish_connection(:adapter=>'postgis', :database=>'#{dbname}', " +
      ":username=>'#{dbuser}', :password=>'#{password}')")  
    return eval("Custom_#{identifier}.connection")
  end
end
