class Contact < ActiveRecord::Base
  after_initialize :set_defaults, unless: :persisted?
  # The set_defaults will only work if the object is new
  attr_accessor :timetext
  attr_accessor :asset2_names

  belongs_to :createdBy, class_name: "User"
 
  before_save { self.before_save_actions }
  after_save { self.update_scores }
  before_destroy { self.update_scores }

  validates :callsign1,  presence: true, length: { maximum: 50 }
  validates :callsign2,  presence: true, length: { maximum: 50 }


  def before_save_actions
    self.remove_call_suffix
    self.add_user_ids
    self.check_codes_in_location
    self.check_for_same_place_error
    location=self.get_most_accurate_location(true)
    self.add_child_codes(location[:asset]) 
    self.update_classes
    self.callsign1 = callsign1.strip.upcase.encode("UTF-16be", :invalid=>:replace, :replace=>"?").encode('UTF-8')

    self.callsign2 = callsign2.strip.upcase.encode("UTF-16be", :invalid=>:replace, :replace=>"?").encode('UTF-8')
    self.band=self.band_from_frequency
  end

  #####################################################################
  # CALCULATED PARAMETERS
  #####################################################################
  def log
    Log.find_by(id: self.log_id)
  end

  def location1_text
    text=""
    self.activator_assets.each do |al|
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
    self.chaser_assets.each do |al|
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
  
  def activator_asset
    cals=[]
    self.asset1_codes.each do |code|
      cal=Asset.find_by(code: code)
      cals.push(cal)
    end
    cals
  end

  def activator_links_code
    cals=activator_assets
    cals.map{|cal| cal.asset_code}
  end
  
  def activator_links_name
    cals=activator_assets
    cals.map{|cal| cal.asset.name}
  end
  
  def chaser_assets
    cals=[]
    self.asset2_codes.each do |code|
      cal=Asset.find_by(code: code)
      cals.push(cal)
    end
    cals
  end

  def user1
    user=User.find_by_id(user1_id)
    user.first
  end

  def user2
    user=User.find_by_id(user2_id)
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
    if rawmode=="FT8" then found=true end
    if rawmode=="FT4" then found=true end
    if rawmode=="JS8" then found=true end
   
    if found==true then mode=rawmode end
    if rawmode=="DATA" then 
       mode = 'FT8'
    end
    mode
  end

  def band_from_frequency
    self.band=Contact.band_from_frequency(self.frequency)
  end

  def hema_band
    band=Contact.hema_band_from_frequency(self.frequency)
  end

  #####################################################################
  # ON SAVE ACTIONS
  #####################################################################
  def set_defaults
    self.timezone||=Timezone.find_by(name: "UTC").id
  end

  def remove_call_suffix
    if self.callsign1['/'] then self.callsign1=User.remove_call_suffix(self.callsign1) end
    if self.callsign2['/'] then self.callsign2=User.remove_call_suffix(self.callsign2) end
  end

  def add_user_ids
    #look up callsign1 at contact.time
    user1=User.find_by_callsign_date(self.callsign1, self.time, true)
    if user1 then self.user1_id=user1.id end
    #look up callsign2 at contact.time
    user2=User.find_by_callsign_date(self.callsign2, self.time, true)
    if user2 then self.user2_id=user2.id end
  end

  def check_codes_in_location
    if self.asset2_codes==nil or self.asset2_codes==[] or self.asset2_codes==[""] then
      assets=Asset.assets_from_code(self.loc_desc2)
      self.asset2_codes=[]
      assets.each do |asset| 
        if asset and asset[:code] then
          if asset2_codes==[] then 
            self.asset2_codes=["#{asset[:code].to_s}"]
          else
            self.asset2_codes.push("#{asset[:code]}")
          end
        end
      end
    end
  end

  #do not allow activator & chaser to be in same place
  #silently remove chasir location if this happens 
  #better than failing a log upload or save where we have not ability to display error
  def check_for_same_place_error
    self.asset2_codes.each do |code|
      if self.log.asset_codes.include? code then
         logger.debug "Removing invalid asset2 code: "+code
         self.asset2_codes=self.asset2_codes-[code]
         self.loc_desc2="INVALID"
      end
    end
  end

  def replace_master_codes2
    newcodes=[]
    self.asset2_codes.each do |code|
      a=Asset.find_by(code: code)

      if a and a.is_active==false
        if a.master_code then
          code=a.master_code
        end
      end
      newcodes+=[code]
    end
    self.asset2_codes=newcodes.uniq
  end

  def get_all_asset2_codes(asset)
    codes=self.asset2_codes
    newcodes=codes
    if self.location2 then newcodes=newcodes+Asset.child_codes_from_location(location2, asset) end
    codes.each do |code|
      newcodes=newcodes+VkAsset.child_codes_from_parent(code)
    end
    newcodes.uniq
  end

  def update_classes
    asset1_classes=[]
    self.asset1_codes.each do |code|
      asset=Asset.assets_from_code(code)
      if asset and asset.count>0 then
        asset1_classes.push(asset.first[:type])
      end
    end
    self.asset1_classes=asset1_classes

    asset2_classes=[]
    self.asset2_codes.each do |code|
      asset=Asset.assets_from_code(code)
      if asset and asset.count>0 then
        asset2_classes.push(asset.first[:type])
      end
    end
    self.asset2_classes=asset2_classes
  end

  def add_child_codes(asset)
    #just inherit log codes for assets1
    self.asset1_codes=self.log.asset_codes
 
    #then lookup codes for assets2
    self.replace_master_codes2
    self.asset2_codes=self.get_all_asset2_codes(asset)
    self.replace_master_codes2
  end
 
  def get_most_accurate_location(force = false)
    #just inherit location1 from log
    self.location1=self.log.location1

    #location2
    location={location: self.location2, source: self.loc_source2, asset: nil}

    if self.location2==nil then self.loc_source2=nil end

    #for anything other than a user specified location
    if self.loc_source2!='user' then
      # only overwrite a location when asked to
      if self.location2 and force==true then self.loc_source2=nil; self.location2=nil end

      #lookup location for asset2 by finding most accurate asset2 location
      location=Asset.get_most_accurate_location(self.asset2_codes, self.loc_source2)
      self.loc_source2=location[:source]
      self.location2=location[:location]
    end
    location
  end


  def update_scores
    if self.user1_id then
      user=User.find_by_id(self.user1_id)
      if user then
        if Rails.env.production? then 
          user.outstanding=true;user.save;Resque.enqueue(Scorer) 
        elsif Rails.env.development? then
          user.update_score 
          user.check_awards
          user.check_completion_awards('region')
          user.check_completion_awards('district')
        else
          logger.debug "Not updating score for test env call manually if needed"
        end
      end
    end
    if user2_id then
      user=User.find_by_id(self.user2_id)
      if user then
        if Rails.env.production? then 
           user.outstanding=true;user.save;Resque.enqueue(Scorer) 
        else 
          user.update_score 
          user.check_awards
          user.check_completion_awards('region')
          user.check_completion_awards('district')
        end
        user.check_awards
      end
     end
  end

  ###########################################################
  # HELPER ROUTINES
  ###########################################################
  def create_log
    log=Log.new
    log.callsign1=self.callsign1
    log.date=self.date
    log
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
    c.x1=self.x2
    c.x2=self.x1
    c.y1=self.y2
    c.y2=self.y1
    c.altitude1=self.altitude2
    c.altitude2=self.altitude1
    c.location1=self.location2
    c.location2=self.location1
    c.is_qrp1=self.is_qrp2
    c.is_qrp2=self.is_qrp1
    c.is_portable1=self.is_portable2
    c.is_portable2=self.is_portable1
    c.user1_id=self.user2_id
    c.user2_id=self.user1_id
    c.asset1_codes=self.asset2_codes 
    c.asset2_codes=self.asset1_codes 
    c.asset1_classes=self.asset2_classes 
    c.asset2_classes=self.asset1_classes 
    c.id=-self.id
    c
  end

  def convert_user_timezone_to_utc(user)
    if self.time and self.date then
        if user then tz=Timezone.find_by_id(user.timezone) else tz=Timezone.find_by(name: 'UTC') end
        t=(self.date.strftime('%Y-%m-%d')+" "+self.time.strftime('%H:%M')).in_time_zone(tz.name)
        self.date=t.in_time_zone('UTC').strftime('%Y-%m-%d')
        self.time=t.in_time_zone('UTC')
        self.timezone=Timezone.find_by(:name => 'UTC').id
    end
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

  def self.get_from_p2p(user_id,asset1,asset2,date)
    contact=Contact.find_by("user1_id=#{user_id} and '#{asset1}'=ANY(asset1_codes) and '#{asset2}'=ANY(asset2_codes) and date>='#{date}'::date and date<('#{date}'::date+'1 day'::interval)")
    if !contact then contact=Contact.find_by("user2_id=#{user_id} and '#{asset1}'=ANY(asset2_codes) and '#{asset2}'=ANY(asset1_codes) and date>='#{date}'::date and date<('#{date}'::date+'1 day'::interval)") end
    contact
  end 

  def self.band_from_frequency(frequency)
    band=""
    if frequency then 
      if frequency>=0.136 and frequency<=0.137 then band="2190m" end
      if frequency>=0.501 and frequency<=0.504 then band="560m" end
      if frequency>=1.8 and frequency<=2 then band="160m" end
      if frequency>=3.5 and frequency<=4 then band="80m" end
      if frequency>=5.351 and frequency<=5.367 then band="60m" end
      if frequency>=7 and frequency<=7.3 then band="40m" end
      if frequency>=10.1 and frequency<=10.15 then band="30m" end
      if frequency>=14.0 and frequency<=14.35 then band="20m" end
      if frequency>=18.068 and frequency<=18.168 then band="17m" end
      if frequency>=21.0 and frequency<=21.45 then band="15m" end
      if frequency>=24.89 and frequency<=24.99 then band="12m" end
      if frequency>=28.0 and frequency<=29.7 then band="10m" end
      if frequency>=50 and frequency<=54 then band="6m" end
      if frequency>=70 and frequency<=71 then band="4m" end
      if frequency>=144 and frequency<=148 then band="2m" end
      if frequency>=222 and frequency<=225 then band="1.25m" end
      if frequency>=420 and frequency<=450 then band="70cm" end
      if frequency>=902 and frequency<=928 then band="33cm" end
      if frequency>=1240 and frequency<=1300 then band="23cm" end
      if frequency>=2300 and frequency<=2450 then band="13cm" end
      if frequency>=3300 and frequency<=3500 then band="9cm" end
      if frequency>=5650 and frequency<=5925 then band="6cm" end
      if frequency>=10000 and frequency<=10500 then band="3cm" end
      if frequency>=24000 and frequency<=24250 then band="1.25cm" end
      if frequency>=47000 and frequency<=47200 then band="6mm" end
      if frequency>=75500 and frequency<=81000 then band="4mm" end
      if frequency>=119980 and frequency<=120020 then band="2.5mm" end
      if frequency>=142000 and frequency<=149000 then band="2mm" end
      if frequency>=241000 and frequency<=250000 then band="1mm" end
    end
    band
  end

  def self.frequency_from_band(band)
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

  def self.hema_band_from_frequency(frequency)
    band=""
    if frequency then 
      if frequency>=1.8 and frequency<=2 then band="1.8MHz" end
      if frequency>=3.5 and frequency<=4 then band="3.6MHz" end
      if frequency>=5.351 and frequency<=5.367 then band="5MHz" end
      if frequency>=7 and frequency<=7.3 then band="7MHz" end
      if frequency>=10.1 and frequency<=10.15 then band="10MHz" end
      if frequency>=14.0 and frequency<=14.35 then band="14MHz" end
      if frequency>=18.068 and frequency<=18.168 then band="18Mhz" end
      if frequency>=21.0 and frequency<=21.45 then band="21MHz" end
      if frequency>=24.89 and frequency<=24.99 then band="24MHz" end
      if frequency>=28.0 and frequency<=29.7 then band="28MHz" end
      if frequency>=50 and frequency<=54 then band="50MHz" end
      if frequency>=70 and frequency<=71 then band="70MHz" end
      if frequency>=144 and frequency<=148 then band="144MHz" end
      if frequency>=222 and frequency<=225 then band="220MHz" end
      if frequency>=420 and frequency<=450 then band="430MHz" end
      if frequency>=902 and frequency<=928 then band="900MHz" end
      if frequency>=1240 and frequency<=1300 then band="1.24GHz" end
      if frequency>=2300 and frequency<=2450 then band="2.3GHz" end
      if frequency>=3300 and frequency<=3500 then band="3.4GHz" end
      if frequency>=5650 and frequency<=5925 then band="5.7GHz" end
      if frequency>=10000 and frequency<=10500 then band="10GHz" end
      if frequency>=24000 and frequency<=24250 then band="24GHz" end
      if frequency>=47000 and frequency<=47200 then band="47GHz" end
      if frequency>=75500 and frequency<=81000 then band="76GHz" end
      if frequency>=119980 and frequency<=120020 then band="122GHz" end
      if frequency>=142000 and frequency<=149000 then band="136GHz" end
      if frequency>=241000 and frequency<=250000 then band="248GHz" end
    end
    band
  end
end
