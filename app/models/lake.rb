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

def self.add_codes
  ps=Lake.where(is_active: true, code: nil).order(:name)
  ps.each do |p|
   p.code=Lake.get_next_code
   p.save
     puts p.code
  end 
true
end

def self.get_next_code
  ps=Lake.find_by_sql [ "select code from lakes where code is not null order by code desc limit 1" ]
  if ps and ps.count>0 then 
     last_code=ps.first.code
  else
      last_code='ZLL/0000'
  end
  codenum=last_code[-4..-1].to_i
  codenum+=1
  next_code='ZLL/'+codenum.to_s.rjust(4,'0')
end
  
#ZLL/XX-#### code based on region
  def self.add_dist_codes
     lakes=Lake.find_by_sql [ " select * from lakes where dist_code='' or dist_code is null order by coalesce(ST_Area(boundary),0) desc" ]
     lakes.each do |p|
       code=self.get_next_dist_code(p.region)
       p.dist_code=code
       p.save
       puts code +" - "+p.name
     end
  end

  def self.get_next_dist_code(region)
    if !region or region=='' then region='ZZ' end
    last_codes=Lake.find_by_sql [ " select dist_code from lakes where dist_code like 'ZLL/"+region+"-%%' and dist_code is not null order by dist_code desc limit 1;" ]
    if last_codes and last_codes.count>0 and last_codes.first.dist_code then
      last_code=last_codes.first.dist_code
    else
      last_code='ZLL/'+region+"-000"
    end
    next_code=last_code[0..6]+(((last_code[7..9].to_i)+1).to_s.rjust(3,'0'))
    next_code
  end

def self.add_regions
     count=0
     a=Lake.first_by_id
     while a do
       count+=1
       a.add_region
       if a.region==nil then puts a.code+" "+count.to_s+" "+(a.region||"null")+" "+a.name+" "+a.location.as_text end
       a=Lake.next(a.id)
     end
end

def add_region
      if self.location then region=Region.find_by_sql [ %q{ SELECT * 
       FROM regions dp
       WHERE ST_DWithin(ST_GeomFromText('}+self.location.as_text+%q{', 4326), boundary, 2000, false) 
       ORDER BY ST_Distance(ST_GeomFromText('}+self.location.as_text+%q{', 4326), boundary) LIMIT 50; } ]
      else puts "ERROR: place without location. Name: "+self.name+", id: "+self.id.to_s end


#    if self.location then region=Region.find_by_sql [ %q{select id, sota_code, name from regions where ST_Within(ST_GeomFromText('}+self.location.as_text+%q{', 4326), "boundary");} ] else puts "ERROR: place without location. Name: "+self.name+", id: "+self.id.to_s end
    if region and region.count>0 and self.region != region.first.sota_code then
      self.region=region.first.sota_code
      self.save
    end

end

def self.get_polygons
  ls=Lake.where(is_active: true, boundary: nil)
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

