class LakeOld < ActiveRecord::Base
require 'csv'

    establish_connection "lakes"

def self.import(filename)
  count=0
  CSV.foreach(filename, :headers => true) do |row|
    h=row.to_hash
    boundary=h.first[1]
    if boundary[0..6]=="POLYGON" then boundary="MULTIPOLYGON ("+boundary[8..-1]+")" end
    dup=LakeOld.find_by(topo50_fid: h['t50_fid'])
    if !dup then 
       l=LakeOld.create(name: h['name'], topo50_fid: h['t50_fid'], boundary: boundary )
       count+=1
       if count==100 then
         print '.'; $stdout.flush
         count=1
       end
    end
  end
  true
end

def self.mark()
  ActiveRecord::Base.connection.execute("update lake_olds set is_active=true where name is not null;")
end

def self.merge_duplicates
  LakeOld.where(is_active: true).each do |l|
    l.reload
    if l.is_active and l.name and l.name.length>0  then       
      #print '.'; $stdout.flush

      ls=LakeOld.find_by_sql [ "select l2.* from lake_olds l1 inner join lake_olds l2 on (ST_Intersects(l1.boundary, l2.boundary) and  unaccent(l1.name)=unaccent(l2.name) and l1.id!=l2.id) where l1.id='"+l.id.to_s+"';"] 

      if ls and ls.count>0 then
        #print '#'; $stdout.flush
        comb=nil 
        ids=ls.map{ |l2| l2.id }.join(',')
        ids=ids+","+l.id.to_s
        ids.split(',').each do |l2|
          areas=LakeOld.find_by_sql [ " select ST_Area(boundary) as id from lake_olds where id in ("+l2+"); " ]
          puts "Areas before merge: "+areas.first.id.to_s
        end

        comb=LakeOld.find_by_sql [ " select st_multi(st_buffer(ST_Union(st_buffer(boundary,0,00001)),-0.00001)) as boundary from lake_olds where id in ("+ids+"); " ]
        poly=comb.first.boundary.as_text
        ls.each do |l2|
          l2.is_active=false
          l2.save
          puts "Merged and deleted "+(l2.name||"unnamed")+" "+l2.id.to_s+" as duplicate of "+(l.name||"unnamed")+l.id.to_s
        end
        l.boundary=poly
        l.save 
        areas=LakeOld.find_by_sql [ " select ST_Area(boundary) as id from lake_olds where id in ("+l.id.to_s+"); " ]
        puts "Area after merge: "+areas.first.id.to_s
      end
    end
  
  end
  true 
end
  
def self.delete_unmatched
  ActiveRecord::Base.connection.execute("delete from lakes where is_active is not true;")
end

def self.add_centroids
  p=Lake.first_by_id
  while p do
    puts p.id
    if p.location==nil then
      location=p.calc_location
      if location then p.location=location; p.save; end
       p.save
    end
    p=Lake.next(p.id)
  end

  true
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

def calc_location
   location=nil
   if self.id then
        locations=Lake.find_by_sql [ 'select id, CASE
                  WHEN (ST_ContainsProperly(boundary, ST_Centroid(boundary)))
                  THEN ST_Centroid(boundary)
                  ELSE ST_PointOnSurface(boundary)
                END AS location from lakes where id='+self.id.to_s ]
        if locations and locations.count>0 then location=locations.first.location else location=nil end
     end
   location
end


def self.first_by_id
  a=Lake.where("id > ? and is_active=true",0).order(:id).first
end


def self.next(id)
  a=Lake.where("id > ? and is_active=true",id).order(:id).first
end

end

