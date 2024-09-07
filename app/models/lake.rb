class Lake < ActiveRecord::Base
require 'csv'

    establish_connection "lakes"

def self.import
  Nzgdb.where(feat_type: 'Lake', is_active: true).each do |place|
    lake=Lake.find_by(topo50_fid: place.feat_id) 
    if !lake then
      lake=Lake.new
      puts "Adding new lake "+place.name
    else
      if place.WKT!=lake.location or place.name != lake.name then
        puts "Updating old place #{lake.name} to #{place.name} at #{lake.location} to #{place.WKT}"
      end
    end
    lake.topo50_fid=place.feat_id
    lake.name=place.name
    lake.location=place.WKT
    lake.old_code=place.status
    lake.is_active=true
    lake.save
  end 
end

def self.remove_duplicates
  ls=Lake.where(is_active: true)
  #pass 1 - official prefferred
  ls.each do |l|
    dups=Lake.where('topo50_fid = ? and id!=? and is_active=true', l.topo50_fid, l.id)
    if dups and dups.count>0  then
     puts l.old_code+" "+l.name
     dups.each do |dup|
       if l.old_code[0..7]=="Official" then dup.is_active=false; dup.save; end
     end
    puts "================"
   end
  end; true
   #pass 1 - recorded prefferred
  ls.each do |l|
    dups=Lake.where('topo50_fid = ? and id!=? and is_active=true', l.topo50_fid, l.id)
    if dups and dups.count>0  then
     puts l.old_code+" "+l.name
     dups.each do |dup|
       if l.old_code[0..18]=="Unofficial Recorded" then dup.is_active=false; dup.save; end
     end
    puts "================"
   end
  end; true

end


end

