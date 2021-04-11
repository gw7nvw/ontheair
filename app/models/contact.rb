class Contact < ActiveRecord::Base
  after_initialize :set_defaults, unless: :persisted?
  # The set_defaults will only work if the object is new


  belongs_to :createdBy, class_name: "User"
  belongs_to :user1, class_name: "User"
  belongs_to :user2, class_name: "User"
  belongs_to :park1, class_name: "Park"
  belongs_to :park2, class_name: "Park"
  belongs_to :island1, class_name: "Island"
  belongs_to :island2, class_name: "Island"
  belongs_to :hut1, class_name: "Hut"
  belongs_to :hut2, class_name: "Hut"


  before_save { self.callsign1 = callsign1.upcase }
  before_save { self.callsign2 = callsign2.upcase }
  validates :callsign1,  presence: true, length: { maximum: 50 }
  validates :callsign2,  presence: true, length: { maximum: 50 }
  validates :date,  presence: true
  validates :time,  presence: true
  validates :frequency,  presence: true
  validates :mode,  presence: true

  def summit1
    summit1=SotaPeak.where(:short_code => self.summit1_id)
    if summit1 and summit1.count>0 then summit1.first else nil end
  end
  def summit2
    summit2=SotaPeak.where(:short_code => self.summit2_id)
    if summit2 and summit2.count>0 then summit2.first else nil end
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
   if self.frequency>=0.136 and self.frequency<=0.137 then band="2190m" end
   if self.frequency>=0.501 and self.frequency<=0.504 then band="560m" end
   if self.frequency>=1.8 and self.frequency<=2 then band="160m" end
   if self.frequency>=3.5 and self.frequency<=4 then band="80m" end
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
   band
 end

 def user1
   user=User.find_by_sql [ "select * from users where callsign='"+callsign1+"'"]
   user.first
 end
 def user2
   user=User.find_by_sql [ "select * from users where callsign='"+callsign2+"'"]
   user.first
 end

 def hut1_name
    if self.hut1 then 
      name=self.hut1.name
    else "" end
 end

 def hut2_name
    if self.hut2 then 
    name=self.hut2.name
    else "" end
 end

 def island1_name
    if self.island1 then
    name=self.island1.name
    else "" end
 end

 def island2_name
    if self.island2 then
    name=self.island2.name
    else "" end
 end
 
 def summit1_name
    if self.summit1 then
    name=self.summit1.name
    else "" end
 end

 def summit2_name
    if self.summit2 then
    name=self.summit2.name
    else "" end
 end


 def park1_name
    if self.park1 then
    name=self.park1.name
    else "" end
 end

 def park2_name
    if self.park2 then
    name=self.park2.name
    else "" end
 end

 def location1_code
  text=""
  if self.hut1 then text=self.hut1.code 
  elsif self.summit1 then text=self.summit1.summit_code
  elsif self.park1 then text=self.park1.code
  elsif self.island1 then text=self.island1.code 
  end
  if text=="" then
    if self.loc_desc1 then 
       text=self.loc_desc1 
    end
  end
  text
 end

 def location2_code
  text=""
  if self.hut2 then text=self.hut2.code 
  elsif self.summit2 then text=self.summit2.summit_code
  elsif self.park2 then text=self.park2.code
  elsif self.island2 then text=self.island2.code
  end
  if text=="" then
    if self.loc_desc2 then 
       text=self.loc_desc2 
    end
  end
  text
 end

 def location1_text
  text=""
  if self.hut1 then text=self.hut1.name end
  if self.summit1 then text=self.summit1.name end
  if self.park1 then text+=" ("+self.park1.name+") " end
  if self.island1 then text+=" ("+self.island1.name+") " end

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
  if self.hut2 then text=self.hut2.name end
  if self.summit2 then text=self.summit2.name end
  if self.park2 then text+=" ("+self.park2.name+") " end
  if self.island2 then text+=" ("+self.island2.name+") " end

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
   if current_user then tz=Timezone.find_by_id(current_user.timezone) else tz=Timezone.first end
   if self.time then t=self.time.in_time_zone(tz.name).strftime('%Y-%m-%d') end
   t
 end

 def localtime(current_user)
   t=nil
   if current_user then tz=Timezone.find_by_id(current_user.timezone) else tz=Timezone.first end
   if self.time then t=self.time.in_time_zone(tz.name).strftime('%H:%M') end
   t
 end

 def localtimezone(current_user)
   t=nil 
   if current_user then tz=Timezone.find_by_id(current_user.timezone) else tz=Timezone.first end
   if self.time then t=self.time.in_time_zone(tz.name).strftime('%Z') end
   t
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
end
