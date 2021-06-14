class Hut < ActiveRecord::Base
require 'open-uri'

  belongs_to :createdBy, class_name: "User"
  belongs_to :park, class_name: "Park"
  belongs_to :island, class_name: "Island"

  def get_code
    code="ZLH/"+self.id.to_s.rjust(4,'0')
  end

  def codename
    codename=self.code+" - "+self.name
  end

  def find_doc_park
   #ps=Docparks.find_by_sql [ %q{select * from docparks dp where ST_Within(ST_GeomFromText('}+self.location.as_text+%q{', 4326), dp."WKT");} ]
   ps=Crownparks.find_by_sql [ %q{select * from crownparks dp where ST_Within(ST_GeomFromText('}+self.location.as_text+%q{', 4326), dp."WKT");} ]
   if ps and ps.first then 
      Park.find_by_id(ps.first.id)
    else nil end
  end

  def find_park
   ps=Park.find_by_sql [ %q{select * from parks p where ST_Within(ST_GeomFromText('}+self.location.as_text+%q{', 4326), p.boundary);} ]
   if ps then ps.first else nil end
  end

  def find_island
   ps=IslandPolygon.find_by_sql [ %q{select * from island_polygons p where ST_Within(ST_GeomFromText('}+self.location.as_text+%q{', 4326), p."WKT");} ]
   if ps then ps.first else nil end
  end

  def self.assign_all_parks
     hs=self.all;

     hs.each do |h|
       if not h.park_id then
         p=h.find_doc_park
         if not p then 
           p=h.find_park
         end
         if p then 
           h.park_id=p.id
           h.save
         end
       end
     end
    true
  end

  def self.assign_all_islands
     hs=self.all;

     hs.each do |h|
       if not h.island_id then
         p=h.find_island
         if p then
           h.island_id=p.name_id
           h.save
         end
       end
     end
    true
  end
 
  def contacts
      contacts1=Contact.find_by_sql [ "select * from contacts where hut1_id="+self.id.to_s+" or hut2_id="+self.id.to_s  ]
  end 

  def photos
    photos=HutPhotoLink.where(:hut_id => self.id)
  end

  def baggers
      contacts1=Contact.find_by_sql [ "select * from contacts where hut1_id="+self.id.to_s+" or hut2_id="+self.id.to_s  ]

      contacts=[]

      contacts1.each do |contact|
        if contact.callsign1 then contacts.push(contact.callsign1) end
        if contact.callsign2 then contacts.push(contact.callsign2) end
      end

      contacts=contacts.uniq

      users=User.where(callsign: contacts).order(:callsign)
  end
  
  def self.update_links
     huts=Hut.all
     huts.each do |hut|
      if hut.routeguides_link then
        idarr=hut.routeguides_link.split('/')
        if idarr and idarr.count==5 then
          place_id=idarr[4].to_i
        
          #find links
          links=Link.find_by_sql [ %q{select * from links where item_type='URL' and item_url like '%%doc.govt.nz%%' and "baseItem_type"='place' and "baseItem_id"=}+place_id.to_s ]
          if links  then 
            link=links.first
            if link then hut.doc_link=link.item_url end
          end
          links=nil

          links=Link.find_by_sql [ %q{select * from links where item_type='URL' and item_url like '%%tramper%%.nz%%' and "baseItem_type"='place' and "baseItem_id"=}+place_id.to_s ]
          if links then 
            link=links.first
            if link then hut.tramper_link=link.item_url end
          end
          links=nil

          links=Link.find_by_sql [ %q{select * from links where item_type='URL' and item_url like '%%hutbagger.co.nz%%' and "baseItem_type"='place' and "baseItem_id"=}+place_id.to_s ]
          if links then 
            link=links.first
            if link then hut.hutbagger_link=link.item_url end
          end
          hut.save
        end
       end
     end
  end

  def self.find_all_hutbagger_photos
     hs=Hut.all
     hs.each do |h|
       h.find_hutbagger_photos
     end
  end 
  def find_hutbagger_photos
   if self.hutbagger_link and self.hutbagger_link["http"] then 
    url=self.hutbagger_link.gsub(/http\:/,"https:")
    page_string = ""
    open(url) do |f|
      page_string = f.read
    end
  
    got_start=false   
    page_string.each_line do |l|
       if l["<h3>Photos</h3>"] then got_start=true; puts "got start"; puts l end
       if got_start and l["<img src"] then
          puts l
          fs=l.split('"')
          if fs and fs[1] and fs[1]["img"] then
            link_url="https://hutbagger.co.nz"+fs[1]
            dups=HutPhotoLink.where(:url => link_url)
            if !dups or dups.count==0 then
              hpl=HutPhotoLink.new
              hpl.hut_id=self.id
              hpl.url=link_url
              hpl.save
            end
          end
       end 
    end
     true
   end
  end
  def self.add_codes
     ps=Hut.all
     ps.each do |p|
       p.code=p.get_code
       p.save
     end
  end
def self.add_regions
     count=0
     huts=Hut.all
     huts.each do |a|
       if a.region==nil or a.region=="" then
         count+=1
         a.add_region
         if a.region==nil then puts a.code+" "+count.to_s+" "+(a.region||"null")+" "+a.name+" "+a.location.as_text end
       end
     end
end

def add_region
      if self.location then region=Region.find_by_sql [ %q{ SELECT * 
       FROM regions dp
       WHERE ST_DWithin(ST_GeomFromText('}+self.location.as_text+%q{', 4326), boundary, 100000, false) 
       ORDER BY ST_Distance(ST_GeomFromText('}+self.location.as_text+%q{', 4326), boundary) LIMIT 50; } ]
      else puts "ERROR: place without location. Name: "+self.name+", id: "+self.id.to_s end

    if region and region.count>0 then #and self.region != region.first.sota_code then
      self.region=region.first.sota_code
      self.save
    end
end
  def self.add_dist_codes
     islands=Hut.find_by_sql [ " select * from huts where dist_code='' or dist_code is null order by name" ]
     islands.each do |p|
       code=self.get_next_dist_code(p.region)
       p.dist_code=code
       p.save
       puts code +" - "+p.name
     end
  end

  def self.get_next_dist_code(region)
    if !region or region=='' then region='ZZ' end
    last_codes=Hut.find_by_sql [ " select dist_code from huts where dist_code like 'ZLH/"+region+"-%%' and dist_code is not null order by dist_code desc limit 1;" ]
    if last_codes and last_codes.count>0 and last_codes.first.dist_code then
      last_code=last_codes.first.dist_code
    else
      last_code='ZLH/'+region+"-000"
    end
    next_code=last_code[0..6]+(((last_code[7..9].to_i)+1).to_s.rjust(3,'0'))
    next_code
  end

end

