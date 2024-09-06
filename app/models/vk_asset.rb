class VkAsset < ActiveRecord::Base

#fake ZL asset fields
def url
  url='/vkassets/'+self.get_safecode
end

def minor
   false
end

def maidenhead
 ""
end

def is_active
   true
end

def type
   nil
end

def self.import
  self.destroy_all
  url="http://parksnpeaks.org/api/SITES"
    data = JSON.parse(open(url).read)
    if data then
      data.each do |site|
        if site and site["ID"] and site["ID"][0..1]=="VK" and site["ID"].length>4 then
          p=VkAsset.new
          p.award=site["Award"]
          p.wwff_code=site["Location"]
          p.shire_code=site["ShireID"]
          p.code=site["ID"]
          if p.code[0..3]=="VKFF" then
            p.wwff_code=p.code
          end
          p.name=site["Name"]
          p.site_type=site["Type"]
          p.latitude=site["Latitude"]
          p.longitude=site["Longitude"]
          p.location='POINT('+p.longitude.to_s+' '+p.latitude.to_s+')'
          puts "Adding: "+p.code+" ["+p.name+"]" 
          if p.wwff_code then
            detailurl="http://parksnpeaks.org/api/PARK/WWFF/"+p.wwff_code
            ddraw=open(detailurl).read
            if ddraw and ddraw.length>2 then detaildata=JSON.parse(ddraw) else detaildata=nil end
            if detaildata then
               p.pota_code=detaildata[0]["POTAID"]
              p.state=detaildata[0]["State"]
              p.region=detaildata[0]["Region"]
              p.district=detaildata[0]["District"]
            end
          end
          p.save
        end
      end
    end
 end

 def self.add_pota_parks
   assets=VkAsset.find_by_sql [ " select * from vk_assets where award='WWFF' and pota_code is not null "]
   assets.each do |asset|
     va=asset.dup
     va.code=va.pota_code
     va.award='POTA'
     va.save
   end
 end

 def get_safecode
    self.code.gsub('/','_')
 end
 def external_url
   if self.award=="HEMA" then
     url='https://parksnpeaks.org/showAward.php?award=HEMA'
   elsif self.award=="SiOTA" then
     url='https://www.silosontheair.com/silos/#'+self.code.to_s
   elsif self.award=="POTA" then
     url='https://pota.app/#/park/'+self.code.to_s
   elsif self.award=="SOTA" then
     url="https://summits.sota.org.uk/summit/"+self.code.to_s
   elsif self.award=="WWFF" then
     url='https://parksnpeaks.org/getPark.php?actPark='+self.code.to_s+'&submit=Process'
   else
     url='/assets'
   end
   url
 end
 def codename
  "["+self.code+"] "+self.name
 end

 def wwff_asset
   asset=nil
   if self.award != "WWFF" then
     if self.wwff_code and self.wwff_code.length>0 then
       asset=VkAsset.find_by(code: self.wwff_code)
     end
   end
   asset
 end
 def pota_asset
   asset=nil
   if self.award != "POTA" then
     if self.pota_code and self.pota_code.length>0 then
       asset=VkAsset.find_by(code: self.pota_code)
       if asset then
         asset.award='POTA'
         asset.code=self.pota_code
       end
     end
   end
   asset
 end

 def contained_by_assets
   assets=[]
   if self.pota_asset then assets.push(self.pota_asset) end
   if self.wwff_asset then assets.push(self.wwff_asset) end
   assets
 end

 def contains_assets
   assets=[]

   if self.award=='WWFF' then
     assets=VkAsset.where(wwff_code: self.code)
   elsif self.award=='POTA' then
     assets=VkAsset.where(pota_code: self.code)
   end
   assets
 end
 def self.containing_codes_from_parent(code)
   codes=[]
   code=code.upcase
   a=VkAsset.find_by(code: code.split(' ')[0])
 
   if a then codes=a.contained_by_assets.map{|a| a.code} end
   codes
 end

end
