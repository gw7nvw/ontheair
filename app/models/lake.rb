class Lake < ActiveRecord::Base
require 'csv'

    establish_connection "lakes"

def self.import
  Nzgdb.where(feat_type: 'Lake', is_active: true).each do |place|
    lake=Lake.find_by(id: place.name_id) 
    if !lake then
      lake=Lake.new
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

def self.add_codes
  ps=Lake.where(is_active: true).order(:name)
  rec=1
  ps.each do |p|
   p.code='ZLL/'+rec.to_s.rjust(4,'0')
   rec+=1
   p.save
     puts p.code
  end 
true
end

def self.get_polygons
  ls=Lake.where(is_active: true)
  ls.each do |l|
    lakes=LakeOld.find_by_sql [ %q{select * from lake_olds where is_active=true and ST_Within(ST_GeomFromText('}+l.location.as_text+%q{',4326), boundary);} ]
    if !lakes or lakes.count==0 then
      lakes=LakeOld.find_by_sql [ %q{ SELECT * 
       FROM lake_olds dp
       WHERE is_active=true and ST_DWithin(ST_GeomFromText('}+l.location.as_text+%q{', 4326), boundary, 5000, false) 
       ORDER BY ST_Distance(ST_GeomFromText('}+l.location.as_text+%q{', 4326), boundary) LIMIT 50; } ]
    end
    if lakes and lakes.count>0 then
      found=false
      lakes.each do |lake|
        l_name=l.name.gsub(/[^0-9a-z]/i, '').gsub('Lakes','').gsub('Lake','')
        lake_name=lake.name.gsub(/[^0-9a-z]/i, '').gsub('Lakes','').gsub('Lake','')
        if found==false and ( l_name==lake_name or l_name.include? lake_name or lake_name.include? l_name) then
  
          if l.name != lake.name then puts "Matched "+(l.name||"unnamed")+" with "+(lake.name||"unnamed") end
          l.boundary=lake.boundary
          l.save
          found=true
        end
      end
      if found==false then puts "Failed to find "+(l.name||"unnamed")+". Best was "+ lakes.first.name end
    end
  end
 true
end


def self.first_by_id
  a=Lake.where("id > ? and is_active=true",0).order(:id).first
end


def self.next(id)
  a=Lake.where("id > ? and is_active=true",id).order(:id).first
end

end

