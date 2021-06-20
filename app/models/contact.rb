class Contact < ActiveRecord::Base
  after_initialize :set_defaults, unless: :persisted?
  # The set_defaults will only work if the object is new
  attr_accessor :timetext
  attr_accessor :asset2_names

  belongs_to :createdBy, class_name: "User"
  belongs_to :user1, class_name: "User"
  belongs_to :user2, class_name: "User"
#  belongs_to :park1, class_name: "Park"
#  belongs_to :park2, class_name: "Park"
  belongs_to :island1, class_name: "Island"
  belongs_to :island2, class_name: "Island"
  belongs_to :hut1, class_name: "Hut"
  belongs_to :hut2, class_name: "Hut"

 

  before_save { self.callsign1 = callsign1.upcase }
  before_save { self.callsign2 = callsign2.upcase }
  before_save { self.check_codes_in_location }
  after_save { self.update_scores }
  before_destroy { self.update_scores }

  validates :callsign1,  presence: true, length: { maximum: 50 }
  validates :callsign2,  presence: true, length: { maximum: 50 }
#  validates :date,  presence: true
#  validates :time,  presence: true
#  validates :frequency,  presence: true
#  validates :mode,  presence: true

  def check_codes_in_location
    if self.asset1_codes==nil or self.asset1_codes==[] or self.asset1_codes==[""] then
      assets=Asset.assets_from_code(self.loc_desc1)
      self.asset1_codes=[]
      assets.each do |asset| 
        if asset and asset[:type]
          if asset2_codes==[] then 
            self.asset1_codes=["#{asset[:code].to_s}"]
          else
            self.asset1_codes.push("#{asset[:code]}")
          end
        end
      end
    end
    if self.asset2_codes==nil or self.asset2_codes==[] or self.asset2_codes==[""] then
      assets=Asset.assets_from_code(self.loc_desc2)
      self.asset2_codes=[]
      assets.each do |asset| 
        if asset and asset[:type]
          if asset2_codes==[] then 
            self.asset2_codes=["#{asset[:code].to_s}"]
          else
            self.asset2_codes.push("#{asset[:code]}")
          end
        end
      end
    end
      
  end

 def location1_text
  text=""
  self.activator_asset_links.each do |al|
    text+=al.codename+ " "
  end

  if text=="" then
    if self.loc_desc1 then
       text=self.loc_desc1
    end
    if self.x1 and self.y1 then
       text+=" (E"+self.x1.to_s+" N"+self.y1.to_s+")"
    end
  end
  text
 end
 def location2_text
  text=""
  self.chaser_asset_links.each do |al|
    text+=al.codename+ " "
  end

  if text=="" then
    if self.loc_desc2 then
       text=self.loc_desc2
    end
    if self.x2 and self.y2 then
       text+=" (E"+self.x2.to_s+" N"+self.y2.to_s+")"
    end
  end
  text
 end

def activator_asset_links
  cals=[]
  self.asset1_codes.each do |code|
    cal=Asset.find_by(code: code)
    cals.push(cal)
  end
  cals
end

def activator_links_code
  cals=activator_asset_links
  cals.map{|cal| cal.asset_code}
end

def activator_links_name
  cals=activator_asset_links
  cals.map{|cal| cal.asset.name}
end

def chaser_asset_links
  cals=[]
  self.asset2_codes.each do |code|
    cal=Asset.find_by(code: code)
    cals.push(cal)
  end
  cals
end


  def adif_mode
    mode=""
    rawmode=self.mode.upcase
    if rawmode[0..2]=="LSB" then rawmode="SSB" end
    if rawmode[0..2]=="USB" then rawmode="SSB" end
    if rawmode[0..2]=="SSB" then rawmode="SSB" end
    found=false
    if rawmode=="AM" then found=true end
    if rawmode=="CW" then found=true end
    if rawmode=="FM" then found=true end
    if rawmode=="SSB" then found=true end
    if rawmode=="DSTAR" then found=true end
   
    if found==true then mode=rawmode end
    mode 
  end

  def set_defaults
    self.timezone||=Timezone.find_by(name: "UTC").id
    self.is_qrp1=true
  end

 def band
   band=""
   if self.frequency then 
     if self.frequency>=0.136 and self.frequency<=0.137 then band="2190m" end
     if self.frequency>=0.501 and self.frequency<=0.504 then band="560m" end
     if self.frequency>=1.8 and self.frequency<=2 then band="160m" end
     if self.frequency>=3.5 and self.frequency<=4 then band="80m" end
     if self.frequency>=5.351 and self.frequency<=5.367 then band="60m" end
     if self.frequency>=7 and self.frequency<=7.3 then band="40m" end
     if self.frequency>=10.1 and self.frequency<=10.15 then band="30m" end
     if self.frequency>=14.0 and self.frequency<=14.35 then band="20m" end
     if self.frequency>=18.068 and self.frequency<=18.168 then band="17m" end
     if self.frequency>=21.0 and self.frequency<=21.45 then band="15m" end
     if self.frequency>=24.89 and self.frequency<=24.99 then band="12m" end
     if self.frequency>=28.0 and self.frequency<=29.7 then band="10m" end
     if self.frequency>=50 and self.frequency<=54 then band="6m" end
     if self.frequency>=70 and self.frequency<=71 then band="4m" end
     if self.frequency>=144 and self.frequency<=148 then band="2m" end
     if self.frequency>=222 and self.frequency<=225 then band="1.25m" end
     if self.frequency>=420 and self.frequency<=450 then band="70cm" end
     if self.frequency>=902 and self.frequency<=928 then band="33cm" end
     if self.frequency>=1240 and self.frequency<=1300 then band="23cm" end
     if self.frequency>=2300 and self.frequency<=2450 then band="13cm" end
     if self.frequency>=3300 and self.frequency<=3500 then band="9cm" end
     if self.frequency>=5650 and self.frequency<=5925 then band="6cm" end
     if self.frequency>=10000 and self.frequency<=10500 then band="3cm" end
     if self.frequency>=24000 and self.frequency<=24250 then band="1.25cm" end
     if self.frequency>=47000 and self.frequency<=47200 then band="6mm" end
     if self.frequency>=75500 and self.frequency<=81000 then band="4mm" end
     if self.frequency>=119980 and self.frequency<=120020 then band="2.5mm" end
     if self.frequency>=142000 and self.frequency<=149000 then band="2mm" end
     if self.frequency>=241000 and self.frequency<=250000 then band="1mm" end
   end
   band
 end

 def self.band_to_freq(band)
   band=band.downcase
   frequency=nil
     if band=="2190m" then frequency=0.136  end
     if band=="560m" then frequency=0.501  end
     if band=="160m" then frequency=1.8 end
     if band=="80m" then frequency=3.5 end
     if band=="60m" then frequency=5.3515 end
     if band=="40m" then frequency=7 end 
     if band=="30m" then frequency=10.1 end 
     if band=="20m" then frequency=14.0 end 
     if band=="17m" then frequency=18.068 end
     if band=="15m" then frequency=21.0  end
     if band=="12m" then frequency=24.89 end
     if band=="10m" then frequency=28.0 end
     if band=="6m" then frequency=50  end
     if band=="4m" then frequency=70  end
     if band=="2m" then frequency=144 end
     if band=="1.25m" then frequency=222  end
     if band=="70cm" then frequency=420  end
     if band=="33cm" then frequency=902 end
     if band=="23cm" then frequency=1240  end
     if band=="13cm" then frequency=2300 end
     if band=="9cm" then frequency=3300  end
     if band=="6cm" then frequency=5650  end
     if band=="3cm" then frequency=10000 end
     if band=="1.25cm" then frequency=24000 end 
     if band=="6mm" then frequency=47000 end 
     if band=="4mm"  then frequency=75500 end
     if band=="2.5mm" then frequency=119980 end
     if band=="2mm" then frequency=142000 end
     if band=="1mm" then frequency=241000 end
   frequency
 end

 def user1
   user=User.find_by_sql [ "select * from users where callsign='"+callsign1+"'"]
   user.first
 end
 def user2
   user=User.find_by_sql [ "select * from users where callsign='"+callsign2+"'"]
   user.first
 end

 def timezonename
   timezonename=""
   if self.timezone!="" then
     tz=Timezone.find_by_id(self.timezone) 
     if tz then timezonename=tz.name end
   end
   timezonename
 end

 def localdate(current_user)
   t=nil
   if current_user then tz=Timezone.find_by_id(current_user.timezone) else tz=Timezone.find_by(name: 'UTC') end
   if self.time then t=self.time.in_time_zone(tz.name).strftime('%Y-%m-%d') end
   t
 end

 def localtime(current_user)
   t=nil
   if current_user then tz=Timezone.find_by_id(current_user.timezone) else tz=Timezone.find_by(name: 'UTC') end
   if self.time then t=self.time.in_time_zone(tz.name).strftime('%H:%M') end
   t
 end

 def localtimezone(current_user)
   t=nil 
   if current_user then tz=Timezone.find_by_id(current_user.timezone) else tz=Timezone.find_by(name: 'UTC') end
   if self.time then t=self.time.in_time_zone(tz.name).strftime('%Z') end
   t
 end

 def update_scores
   callsign=self.callsign1
   if callsign and callsign.length>0 then
     user=User.find_by(callsign: callsign)
     if not user then
       user=User.create(callsign: callsign, activated: false, password: 'dummy', password_confirmation: 'dummy', timezone: 1)
     end
     if Rails.env.production? then user.outstanding=true;user.save;Resque.enqueue(Scorer) else user.update_score end
   end
   callsign=self.callsign2
   if callsign and callsign.length>0 then
     user=User.find_by(callsign: callsign)
     if not user then
       user=User.create(callsign: callsign, activated: false, password: 'dummy', password_confirmation: 'dummy', timezone: 1)
     end
     if Rails.env.production? then user.outstanding=true;user.save;Resque.enqueue(Scorer) else user.update_score end
   end
 end

 def reverse
   c=self.dup
   c.callsign1=self.callsign2
   c.callsign2=self.callsign1
   c.power1=self.power2
   c.power2=self.power1
   c.signal1=self.signal2
   c.signal2=self.signal1
   c.comments1=self.comments2
   c.comments2=self.comments1
   c.loc_desc1=self.loc_desc2
   c.loc_desc2=self.loc_desc1
   c.hut1_id=self.hut2_id
   c.hut2_id=self.hut1_id
   c.park1_id=self.park2_id
   c.park2_id=self.park1_id
   c.x1=self.x2
   c.x2=self.x1
   c.y1=self.y2
   c.y2=self.y1
   c.altitude1=self.altitude2
   c.altitude2=self.altitude1
   c.location1=self.location2
   c.location2=self.location1
   c.island1_id=self.island2_id
   c.island2_id=self.island1_id
   c.is_qrp1=self.is_qrp2
   c.is_qrp2=self.is_qrp1
   c.is_portable1=self.is_portable2
   c.is_portable2=self.is_portable1
   c.user1_id=self.user2_id
   c.user2_id=self.user1_id
  
   c
 end

 def self.updatealltimes
   cs=Contact.all
   cs.each do |contact|
    if contact.time and contact.date and contact.timezonename=='NZDT' then
        if contact.time.hour<13 then contact.date=contact.date-1.day end
        contact.time=contact.time-13.hours
        contact.timezone=Timezone.find_by(:name => 'UTC')
    end
    if contact.time and contact.date and contact.timezonename=='NZST' then
        if contact.time.hour<12 then contact.date=contact.date-1.day end
        contact.time=contact.time-12.hours
        contact.timezone=Timezone.find_by(:name => 'UTC')
    end
    if contact.time and contact.date then
        contact.time=(contact.date.strftime('%Y-%m-%d')+" "+contact.time.strftime('%H:%M:%S')).in_time_zone("UTC")
    end
   contact.save
   end


 end
  def convert_to_utc(current_user)
    if self.time and self.date then
        if current_user then tz=Timezone.find_by_id(current_user.timezone) else tz=Timezone.find_by(name: 'UTC') end
        t=(self.date.strftime('%Y-%m-%d')+" "+self.time.strftime('%H:%M')).in_time_zone(tz.name)
        self.date=t.in_time_zone('UTC').strftime('%Y-%m-%d')
        self.time=t.in_time_zone('UTC')
        self.timezone=Timezone.find_by(:name => 'UTC').id
    end
  end

def find_asset1_by_type(asset_type)
 asset1=nil
  asset_codes=self.asset1_codes
  asset_codes.each do |asset_code|
    if asset_code then
       asset=Asset.assets_from_code(asset_code)
       if asset and asset.count>0 and asset.first[:type]==asset_type then
          asset1=asset.first
       end
    end
  end
  asset1
end


def find_asset2_by_type(asset_type)
  asset2=nil
  asset_codes=self.asset2_codes
  asset_codes.each do |asset_code|
    if asset_code then 
       asset=Asset.assets_from_code(asset_code)
       if asset and asset.count>0 and asset.first[:type]==asset_type then
          asset2=asset.first
       end
    end
  end
  asset2
end

def self.migrate_to_codes
   contacts=Contact.all
    contacts.each do |contact|
      puts contact.id.to_s
      codes=[]
      if contact.hut1_id and Hut.find_by(id: contact.hut1_id) then codes.push(Hut.find_by(id: contact.hut1_id).code) end
      if contact.park1_id and Park.find_by(id: contact.park1_id) then codes.push(Park.find_by(id: contact.park1_id).code) end
      if contact.island1_id and Island.find_by(id: contact.island1_id) then codes.push(Island.find_by(id: contact.island1_id).code) end
      if contact.summit1_id and contact.summit1_id.length>0 and SotaPeak.find_by(short_code: contact.summit1_id) then codes.push(SotaPeak.find_by(short_code: contact.summit1_id).summit_code) end
      if codes==[] then
        #try location
        links=Asset.assets_from_code(contact.loc_desc1) 
        codes=[]
        links.each do |link|
          if link and link[:code] then codes.push(link[:code]) end
        end
      end
      contact.asset1_codes=codes
      codes=[]
      if contact.hut2_id and Hut.find_by(id: contact.hut2_id) then codes.push(Hut.find_by(id: contact.hut2_id).code) end
      if contact.park2_id and Park.find_by(id: contact.park2_id) then codes.push(Park.find_by(id: contact.park2_id).code) end
      if contact.island2_id and Island.find_by(id: contact.island2_id) then codes.push(Island.find_by(id: contact.island2_id).code) end
      if contact.summit2_id and contact.summit2_id.length>0 and SotaPeak.find_by(short_code: contact.summit2_id) then codes.push(SotaPeak.find_by(short_code: contact.summit2_id).summit_code) end
      if codes==[] then
        #try location
        codes=[]
        links=Asset.assets_from_code(contact.loc_desc2) 
        links.each do |link|
          if link and link[:code] then codes.push(link[:code]) end
        end
      end
      contact.asset2_codes=codes
      contact.save
    end
end
  
def self.migrate_to_distcodes
  cs=Contact.all
  cs.each do |c|
  codes=[]
  puts c.asset1_codes 
  puts c.asset2_codes 
  c.asset1_codes.each do |a|
    asset=Asset.find_by(old_code: a)
    if !asset then asset=Asset.find_by(code: a) end
    if asset then codes.push(asset.code) else codes.push(a) end
  end
  c.asset1_codes=codes
  codes=[]
  c.asset2_codes.each do |a|
    asset=Asset.find_by(old_code: a)
    if !asset then asset=Asset.find_by(code: a) end
    if asset then codes.push(asset.code) else codes.push(a) end
  end
  c.asset2_codes=codes
  c.save
  end
end

end
