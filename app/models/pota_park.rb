class PotaPark < ActiveRecord::Base

##################################################
#
# Update parks from POTA
#
# From rails console production
#
# Call: PotaPark.import(false||true)
#   - Call with false for a test run, or true to apply changes
#
# - Reads POTA parks from POTA by geographical search box
# - POTA location is poor and boundary not known to POTA so we must match
#   the pota park against LINZ park data (in assets) to find the correct boundary
# - Checks all parks against existing PotaPark list
# - Updates name if required for existing parks
# - For new parks:
#   - Searches for a ZLP park with matching or close name
#   - If a good match, extracts location data from ZLP park and applies to POTA park
#   - If several matches, asks user to choose matching park
#   - If no match, asks user to supply a ZLP reference 
# - If create='true' was requested:
#   - saves the resulting pota park
#   - updates / creates the relevent entry in Assets
#
# Note: because creating parks and matching them to LINZ data is a real pain, we do not 
# clear the PotaPark table before each refresh.  This means that no 'delete' or 'retire' 
# of old parks will occur automatically.  It is also unclear whether retired parks will be
# sent in the data from POTA, as no retired or retired_at field is provided by POTA.

def self.import(create=true)

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

         if is_invalid==false and create==true then
           p.save
           a=Asset.add_pota_park(p, park)
         end
      end
    end
  end
end
 
end

