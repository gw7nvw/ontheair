class Log < ActiveRecord::Base
  validates :callsign1,  presence: true, length: { maximum: 50 }

  belongs_to :createdBy, class_name: "User"
  before_save { self.before_save_actions }
  after_save { update_contacts }
  #attr_accessor :asset_names

  def before_save_actions
    self.add_user_ids
    self.check_codes_in_location
    #self.get_most_accurate_location
    self.remove_suffix
    self.callsign1=self.callsign1.strip.upcase.encode("UTF-16be", :invalid=>:replace, :replace=>"?").encode('UTF-8')
  end

  def add_user_ids
    #look up callsign1 at contact.time
    user1=User.find_by_callsign_date(self.callsign1, self.date, true)
    if user1 then self.user1_id=user1.id end
  end

  def asset_names
    asset_names=self.assets.map{|asset| asset.name}
    if !asset_names then asset_names="" end
    asset_names
  end

  def check_codes_in_location
    if self.asset_codes==nil or self.asset_codes==[] or self.asset_codes==[""] then
      assets=Asset.assets_from_code(self.loc_desc1)
      self.asset_codes=[]
      assets.each do |asset|
        if asset and asset[:code] then
          if asset_codes==[] then
            self.asset_codes=["#{asset[:code].to_s}"]
          else
            self.asset_codes.push("#{asset[:code]}")
          end
        end
      end
    end
    self.get_most_accurate_location
    self.add_child_codes
  end

  def get_most_accurate_location(force = false)
    codes=self.asset_codes
   # only overwrite a location with a point locn
   if self.location1 and force==false then loc_point=true else loc_point=false end

    accuracy=999999999999
    codes.each do |code|
      puts "DEBUG: assessing code #{code}"
      assets=Asset.find_by_sql [ " select id, asset_type, location, area from assets where code='#{code}' limit 1" ]

      if assets then asset=assets.first else asset=nil end

      if asset then
        if asset.type.has_boundary then
          if loc_point==false and ((!(asset.area.nil?) and asset.area<accuracy) or (asset.area.nil? and (accuracy == 999999999999))) then
            self.location1=asset.location 
            accuracy=asset.area
            loc_point=false
            puts "DEBUG: Assigning polygon locn"
          end
        else
          if loc_point==true then
            puts "Multiple POINT locations found for log #{self.id.to_s}"
            #do not overwrite
          end
          self.location1=asset.location
          loc_point=true
          puts "DEBUG: Assigning point locn"
        end
      end
    end
  end

  def add_child_codes
    self.replace_master_codes
    if !self.do_not_lookup==true then
      self.asset_codes=self.get_all_asset_codes
      self.replace_master_codes
    end
  end

  def replace_master_codes
    newcodes=[]
    self.asset_codes.each do |code|
      a=Asset.find_by(code: code)

      if a and a.is_active==false
        if a.master_code then
          code=a.master_code
        end
      end
      newcodes+=[code]
    end
    self.asset_codes=newcodes.uniq
  end

  def get_all_asset_codes
    codes=self.asset_codes
    newcodes=codes
    newcodes=newcodes+Asset.child_codes_from_location(self.location1)
    codes.each do |code|
      newcodes=newcodes+VkAsset.child_codes_from_parent(code)
    end
    newcodes.uniq
  end

  def asset_code_names
    if self.asset_codes then asset_names=self.asset_codes.map{|ac| asset=Asset.assets_from_code(ac).first; if asset then "["+asset[:code]+"] "+asset[:name] else "" end} else asset_names=[] end
    if !asset_names then asset_names=[] end
    asset_names
  end

 def localdate(currentuser)
   t=nil
   if currentuser then tz=Timezone.find_by_id(currentuser.timezone) else tz=Timezone.find_by(name: 'UTC') end
   cs=Contact.find_by_sql [ " select * from contacts where log_id ="+self.id.to_s+" order by time desc limit 1 " ]
   c1=cs.first 
   if c1 and c1.time then 
       thetime=c1.time 
       t=thetime.in_time_zone(tz.name).strftime('%Y-%m-%d') 
   elsif self.date then
       t=self.date.strftime('%Y-%m-%d')
   else 
     t=""
   end
   t
 end

  def assets
    if self.asset_codes then Asset.where(code: self.asset_codes) else [] end
  end  

  def activator_asset_links
    cals=[]
    self.asset_codes.each do |code|
      cal=Asset.find_by(code: code)
      cals.push(cal)
    end
    cals
  end

  def contacts
    if self.id and self.id>0 then
      cs=Contact.where(log_id: self.id)
    else 
      nil
    end
    cs
  end

  def update_contacts
    contacts=Contact.where(:log_id => self.id)
    contacts.each do |cle|
      cle.callsign1=self.callsign1
      cle.date=self.date
      cle.time=Time.iso8601(self.date.strftime("%Y-%m-%d")+"T"+cle.time.strftime("%H:%M:%SZ")) #pick up changes in date and apply to time
      cle.loc_desc1=self.loc_desc1
      cle.is_qrp1=self.is_qrp1
      cle.power1=self.power1
      cle.is_portable1=self.is_portable1
      cle.x1=self.x1
      cle.y1=self.y1
      cle.location1=self.location1
      #cle.convert_to_utc(User.find_by_callsign_date(cle.callsign1, cle.date))
      cle.asset1_codes=self.asset_codes
      cle.save
    end
  end

def self.migrate_to_codes
   logs=Log.all
    logs.each do |log|
      codes=[]
      if log.hut1_id then codes.push(Hut.find_by(id: log.hut1_id).code) end 
      if log.park1_id then codes.push(Park.find_by(id: log.park1_id).code) end
      if log.island1_id then codes.push(Island.find_by(id: log.island1_id).code) end
      if log.summit1_id and log.summit1_id.length>0 then codes.push(SotaPeak.find_by(short_code: log.summit1_id).summit_code) end
      log.asset_codes=codes
      log.save
    end
end

def self.migrate_to_distcodes
  cs=Log.all
  cs.each do |c|
  codes=[]
  c.asset_codes.each do |a|
    asset=Asset.find_by(old_code: a)
    if !asset then asset=Asset.find_by(code: a) end
    if asset then codes.push(asset.code) else codes.push(a) end
  end
  c.asset_codes=codes
  c.save
  end
end

def self.import_csv(filestr,user,default_callsign,default_location,no_create=false, ignore_error=false, do_not_lookup=false)

  logs=[]
  contacts=[]
  errors=[]
  contacts_per_log=[]
  invalid_log=[]

  log_count=0
  contact_count=0
  #check encoding
  if !filestr.valid_encoding? then
    filestr=filestr.encode("UTF-16be", :invalid=>:replace, :replace=>"?").encode('UTF-8')
  end

  lines=filestr.lines
  # remove header
  record_count=0
  skip_count=0
  lines.each do |line|
    fields=line.split(',')
    if fields[0].upcase=='V2' and fields.count>=9 then
      contact=Contact.new
      protolog=Log.new
      protolog.do_not_lookup=do_not_lookup
      if user then 
        contact.callsign1=default_callsign
        protolog.callsign1=default_callsign
      end
      logid=nil
      timestr=nil
      contact.asset1_codes=[]
      contact.asset2_codes=[]
      if default_location and default_location.length>0 and default_location.strip.length>0 then
        protolog.asset_codes.push(default_location.strip)
        contact.asset1_codes.push(default_location.strip)
      end
 
      contact.timezone=Timezone.find_by(name: "UTC").id
 
 
      #my calls
      value=fields[1]
      if value and value.length>0 and value.strip.length>0 then
         callsign=value.strip.upcase
         #remove suffix
         if callsign['/'] then callsign=Log.remove_suffix(callsign) end
         protolog.callsign1=callsign
         contact.callsign1=callsign
      end
 
      #date
      value=fields[3]
      if value and value.length>0 and value.strip.length>0 then
         protolog.date=value.strip
         contact.date=value.strip
      end
 
      #my location
      value=fields[2]
      if value and value.length>0 and value.strip.length>0 then
         values=value.split(';')
         values.each do |val|
           val=Asset.correct_separators(val.strip)
           protolog.asset_codes.push(val)
           contact.asset1_codes.push(val)
           protolog.is_portable1=true
           contact.is_portable1=true
         end
      end
 
      #time
      value=fields[4]
      if value and value.length>0 and value.strip.length>0 then
        timestr=value.strip.gsub(':','')
      end
 
      #band
      value=fields[5]
      if value and value.length>0 and value.strip.length>0 then
         contact.frequency=value.strip.gsub("MHz","")
      end
 
      #mode
      value=fields[6]
      if value and value.length>0 and value.strip.length>0 then
        contact.mode=value.strip
      end
 
      #other call
       value=fields[7]
      if value and value.length>0 and value.strip.length>0 then
        callsign=value.strip.upcase
        #remove suffix
        if callsign['/'] then callsign=Log.remove_suffix(callsign) end
        contact.callsign2=callsign
      end
 
      #other location
      value=fields[8]
      if value and value.length>0 then
        values=value.split(',')
        values.each do |val|
          val=Asset.correct_separators(val.strip)
          contact.asset2_codes.push(val)
          contact.is_portable2=true
        end
      end
 
      record_count+=1
      protolog.check_codes_in_location
      lc=0
      logs.each do |log|
          #puts "IMPORT: testing"
          #puts log.callsign1, protolog.callsign1, log.callsign1==protolog.callsign1
          #puts log.date,protolog.date,log.date==protolog.date
          #puts log.asset_codes.join(','),protolog.asset_codes.join(','),(protolog.asset_codes-log.asset_codes).empty?
          if log.callsign1==protolog.callsign1 and log.date==protolog.date and (protolog.asset_codes-log.asset_codes).empty? then 
                  logid=lc
                  puts "IMPORT: matched existing log: #{lc.to_s}"
          end  
          lc+=1
      end
      if logid==nil then
         puts "IMPORT: creating new log ("+log_count.to_s+")"
         log_count=logs.count
         lstr=protolog.to_json
         invalid_log[log_count]=true
         logs[log_count]=Log.new(JSON.parse(lstr))
         loguser=User.find_by_callsign_date(logs[log_count].callsign1,logs[log_count].date)
         if loguser and (loguser.id==user.id or user.is_admin) then
           if logs[log_count].valid? then
             puts "Valid log "+log_count.to_s    
             invalid_log[log_count]=false
           else
             errors.push("Record #{record_count.to_s}: Create log #{log_count.to_s} failed: "+logs[log_count].errors.messages.to_s)
           end
         else
           errors.push("Record #{record_count.to_s}: Create log #{log_count.to_s} failed: you cannot create a log for a callsign not registered to your account (#{user.callsign}) at the time of the contact (#{logs[log_count].callsign1} #{logs[log_count].date.to_s})")
         end
         contacts_per_log[log_count]=0       
         logid=log_count
         log_count+=1
      end 
 
      contact.log_id=logid
      #puts "IMPORT: save contact"
      cstr=contact.to_json
      c=JSON.parse(cstr)
      contact=Contact.new(c)
      if timestr.length==1 then timestr="000"+timestr end
      if timestr.length==2 then timestr="00"+timestr end
      if timestr.length==3 then timestr="0"+timestr end
      if timestr and protolog.date then contact.time=protolog.date.strftime("%Y-%m-%d")+" "+timestr[0..1]+":"+timestr[2..3] end
      if !contact.date then
          errors.push("Record #{record_count.to_s}: Save contact #{contact_count.to_s} failed: no date/time")
      elsif (!contact.asset1_codes or contact.asset1_codes.count==0) and (!contact.asset2_codes or contact.asset2_codes.count==0) then
          errors.push("Record #{record_count.to_s}: Save contact #{contact_count.to_s} failed: no activation location for either party")
      else
         res=true
         create=false
         if no_create==true then
           #only save if both calls are registered
           uc=UserCallsign.find_by(callsign: contact.callsign2)
           if uc then 
             res=contact.valid?
             create=true
           else 
             puts "Skipping contact with unknown call: "+contact.callsign2 
             skip_count+=1
             create=false
           end
         else
           #always save
           res=contact.valid?
           create=true
         end
         if !res then 
           puts "IMPORT: save contact failed"
           errors.push("Record #{record_count.to_s}: Save contact #{contact_count.to_s} failed: "+contact.errors.messages.to_s)
         end
         if res and create then
           contacts[contact_count]=contact
           contacts_per_log[contact.log_id]+=1
           contact_count+=1
         end 
      end
    end #end of if valid line
  end #end of lines.each 
 
  good_logs=0 
  #create logs
  lc=0
  logs.each do |log|
    if contacts_per_log[lc]>0 and !invalid_log[lc] then 
      if errors.empty? or ignore_error then
        logs[lc].asset_codes=nil
        if logs[lc].save then
           logs[lc].reload
           good_logs+=1
        else
           errors.push("FATAL: Save log #{lc.to_s} failed: "+logs[lc].errors.messages.to_s)
           invalid_log[lc]=true
        end
      else
        good_logs+=1
      end
    else
      puts "Skipping empty log: "+lc.to_s
    end
    lc+=1
  end

  #create contacts
  cc=0
  good_contacts=0
  contacts.each do |contact|
    if invalid_log[contact.log_id] then
      puts "Skipping contact #{cc.to_s} as log #{contact.log_id.to_s} invalid"
    else
      if errors.empty? or ignore_error then
        contact.log_id=logs[contact.log_id].id
        if contact.save  then
           good_contacts+=1
        else
           errors.push("FATAL: Save contact #{cc.to_s} failed: "+contact.errors.messages.to_s)
        end
      else
        good_contacts+=1
      end
    end
  end
  puts "IMPORT: clean exit"
  puts errors
  return {logs: logs, errors: errors, success: true, good_logs: good_logs, good_contacts: good_contacts}
end
 
     
def self.import(filestr,user,default_callsign,default_location,no_create=false, ignore_error=false,  do_not_lookup=false)

  logs=[]
  contacts=[]
  errors=[]
  contacts_per_log=[]
  invalid_log=[]

  log_count=0
  contact_count=0
  #check encoding
  if !filestr.valid_encoding? then
    filestr=filestr.encode("UTF-16be", :invalid=>:replace, :undef=>:replace, :replace=>"?").encode('UTF-8')
    puts "Invalid"
  end

  filestr =filestr.encode('ASCII', :invalid=>:replace, :undef=>:replace, :replace=>"?").encode('UTF-8')

  # remove header
  if filestr["<EOH>"] or filestr["<eoh>"] then
    logbody=filestr.split(/<EOH>|<eoh>/)[1]
  else
    logbody=filestr
  end

  # check for <eor>
  if logbody["<eor>"] or logbody["<EOR>"] then 
     #ech record terminated by <eor>
     lines=logbody.split(/<EOR>|<eor>/) 
  else
     #if no <eor> then assume one record per line
     lines=logbody.lines
  end

  record_count=0
  skip_count=0
  lines.each do |line|
     contact=Contact.new
     protolog=Log.new
     protolog.do_not_lookup=do_not_lookup
     if user then 
       contact.callsign1=default_callsign.encode('UTF-8')
       protolog.callsign1=default_callsign.encode('UTF-8')
     end
     logid=nil
     timestr=nil
     contact.asset1_codes=[]
     contact.asset2_codes=[]
     if default_location and default_location.length>0 and default_location.strip.length>0 then
       protolog.asset_codes.push(default_location.strip)
       contact.asset1_codes.push(default_location.strip)
     end

     contact.timezone=Timezone.find_by(name: "UTC").id
     #get date from this line
     if line.upcase['QSO_DATE'] then
       #prefetch date
       date=line.upcase.split('<QSO_DATE')[1].split('>')[1][0..7]
       #prefetch assets codes
       locarr=[]

       line.split("<").each do |parm|
         if parm and parm.length>0 then
           key=parm.split('>')[0]
           len=key.split(':')[1]
           key=key.split(':')[0]
           value=parm.split('>')[1]
           if value then
           puts "value: "+value.to_s
           puts "length: "+value.length.to_s
           puts "len: "+len.to_s
           puts "key: "+key
           end

           if len and len.to_i>0 then 
             puts "Truncate"
             value=value[0..(len.to_i)-1] 
             puts "length: "+value.length.to_s
           end
           puts "DEBUG: "+key.downcase
           case (key.downcase)
 
           when "station_callsign"
              if value and value.length>0 and value.strip.length>0 then
                callsign=value.strip.upcase
                #remove suffix
                if callsign['/'] then callsign=Log.remove_suffix(callsign) end
                protolog.callsign1=callsign
                contact.callsign1=callsign
              end
           when "operator"
              if value and value.length>0 and value.strip.length>0 then
                callsign=value.strip.upcase
                #remove suffix
                if callsign['/'] then callsign=Log.remove_suffix(callsign) end
                protolog.callsign1=callsign
                contact.callsign1=callsign
              end
           when "qso_date"
              if value and value.length>0 and value.strip.length>0 then
                protolog.date=value.strip
                contact.date=value.strip
              end
           when "my_wwff_ref"
              if value and value.length>0 and value.strip.length>0 then
                values=value.split(',')
                values.each do |val|
                  val=Asset.correct_separators(val.strip)
                  protolog.asset_codes.push(val)
                  contact.asset1_codes.push(val)
                  protolog.is_portable1=true
                  contact.is_portable1=true
                end
              end
           when "my_sota_ref"
              if value and value.length>0 and value.strip.length>0 then
                values=value.split(',')
                values.each do |val|
                  val=Asset.correct_separators(val.strip)
                  protolog.asset_codes.push(val)
                  contact.asset1_codes.push(val)
                  protolog.is_portable1=true
                  contact.is_portable1=true
                end
              end
           when "my_sig_info"
              if value and value.length>0 and value.strip.length>0 then
                values=value.split(',')
                values.each do |val|
                  val=Asset.correct_separators(val.strip)
                  protolog.asset_codes.push(val)
                  contact.asset1_codes.push(val)
                  protolog.is_portable1=true
                  contact.is_portable1=true
                end
              end
           when "comment"
              if value and value.length>0 then
                protolog.comments1=value.gsub(/\r/,'').gsub(/\n/,'')
                contact.comments1=value.gsub(/\r/,'').gsub(/\n/,'')
              end
           when "my_antenna"
              if value and value.length>0 then
                protolog.antenna1=value.gsub(/\r/,'').gsub(/\n/,'')
                contact.antenna1=value.gsub(/\r/,'').gsub(/\n/,'')
              end
           when "my_rig"
              if value and value.length>0 then
                protolog.transceiver1=value.gsub(/\r/,'').gsub(/\n/,'')
                contact.transceiver1=value.gsub(/\r/,'').gsub(/\n/,'')
              end
           when "my_lat"
              if value and value.length>0 then
                pos=Log.degs_from_deg_min_sec(value)
                contact.y1=pos
                protolog.y1=pos
              end
           when "my_long"
              if value and value.length>0 then
                pos=Log.degs_from_deg_min_sec(value)
                contact.x1=pos
                protolog.x1=pos
              end
           when "my_city"
              if value and value.length>0 and value.strip.length>0 then
                contact.loc_desc1=value.strip
                protolog.loc_desc1=value.strip
              end
           when "tx_pwr"
              if value and value.length>0 and value.strip.length>0 then
                contact.power1=value.strip
                protolog.power1=value.strip
                if value.strip.to_f<=10 then 
                  contact.is_qrp1=true
                  protolog.is_qrp1=true
                end
              end
           when "band"
              if value and value.length>0 and value.strip.length>0 then
                if !contact.frequency then
                  contact.frequency=Contact.band_to_freq(value.strip)
                end
              end
           when "freq"
              if value and value.length>0 and value.strip.length>0 then
                contact.frequency=value.strip
              end
           when "rst_sent"
              if value and value.length>0 and value.strip.length>0 then
                contact.signal2=value.strip
              end
           when "rst_rcvd"
              if value and value.length>0 and value.strip.length>0 then
                contact.signal1=value.strip
              end
           when "time_on"
              if value and value.length>0 and value.strip.length>0 then
                timestr=value.strip.gsub(':','')
              end
           when "time_off"
              if value and value.length>0 and value.strip.length>0 then
                timestr=value.strip.gsub(':','')
              end
           when "lat"
              if value and value.length>0 then
                pos=Log.degs_from_deg_min_sec(value)
                contact.y2=pos
              end
           when "long"
              if value and value.length>0 then
                pos=Log.degs_from_deg_min_sec(value)
                contact.x2=pos
              end
           when "mode"
              if value and value.length>0 and value.strip.length>0 then
                contact.mode=value.strip
              end
           when "submode"
              if value and value.length>0 and value.strip.length>0 then
                contact.mode=value.strip
              end
           when "name"
              if value and value.length>0 and value.strip.length>0 then
                contact.name2=value.strip
              end
           when "call"
              if value and value.length>0 and value.strip.length>0 then
                callsign=value.strip.upcase
                #remove suffix
                if callsign['/'] then callsign=Log.remove_suffix(callsign) end
                contact.callsign2=callsign
              end
           when "qth"
              if value and value.length>0 and value.strip.length>0 then
                contact.loc_desc2=value.strip
              end
           when "rx_pwr"
              if value and value.length>0 and value.strip.length>0 then
                contact.power2=value.strip
                if value.strip.to_f<=10 then 
                  contact.is_qrp2=true
                end
              end
           when "wwff_ref"
              if value and value.length>0 then
                values=value.split(',')
                values.each do |val|
                  val=Asset.correct_separators(val.strip)
                  contact.asset2_codes.push(val)
                  contact.is_portable2=true
                end
              end
           when "sota_ref"
              if value and value.length>0 then
                values=value.split(',')
                values.each do |val|
                  val=Asset.correct_separators(val.strip)
                  contact.asset2_codes.push(val)
                  contact.is_portable2=true
                end
              end
           when "sig_info"
              if value and value.length>0 then
                values=value.split(',')
                values.each do |val|
                  val=Asset.correct_separators(val.strip)
                  contact.asset2_codes.push(val)
                  contact.is_portable2=true
                end
              end
           end
          end #end of if
       end
       record_count+=1
       protolog.check_codes_in_location
       lc=0
       logs.each do |log|
          #puts "IMPORT: testing"
          #puts log.callsign1, protolog.callsign1, log.callsign1==protolog.callsign1
          #puts log.date,protolog.date,log.date==protolog.date
          #puts log.asset_codes.join(','),protolog.asset_codes.join(','),(protolog.asset_codes-log.asset_codes).empty?
          if log.callsign1==protolog.callsign1 and log.date==protolog.date and (protolog.asset_codes-log.asset_codes).empty? then 
                  logid=lc
                  puts "IMPORT: matched existing log: #{lc.to_s}"
          end  
          lc+=1
       end
       if logid==nil then
         puts "IMPORT: creating new log ("+log_count.to_s+")"
         log_count=logs.count
         lstr=protolog.to_json
         invalid_log[log_count]=true
         logs[log_count]=Log.new(JSON.parse(lstr))
         loguser=User.find_by_callsign_date(logs[log_count].callsign1,logs[log_count].date)
         if loguser and (loguser.id==user.id or user.is_admin) then
           if logs[log_count].valid? then
             puts "Valid log "+log_count.to_s    
             invalid_log[log_count]=false
           else
             errors.push("Record #{record_count.to_s}: Create log #{log_count.to_s} failed: "+logs[log_count].errors.messages.to_s)
           end
         else
           errors.push("Record #{record_count.to_s}: Create log #{log_count.to_s} failed: you cannot create a log for a callsign not registered to your account (#{user.callsign}) at the time of the contact (#{logs[log_count].callsign1} #{logs[log_count].date.to_s})")
         end
         contacts_per_log[log_count]=0       
         logid=log_count
         log_count+=1
       end 

       contact.log_id=logid
       #puts "IMPORT: save contact"
       cstr=contact.to_json
       c=JSON.parse(cstr)
       contact=Contact.new(c)
       if timestr.length==1 then timestr="000"+timestr end
       if timestr.length==2 then timestr="00"+timestr end
       if timestr.length==3 then timestr="0"+timestr end
       if timestr and protolog.date then contact.time=protolog.date.strftime("%Y-%m-%d")+" "+timestr[0..1]+":"+timestr[2..3] end
       if !contact.date then
         errors.push("Record #{record_count.to_s}: Save contact #{contact_count.to_s} failed: no date/time")
       elsif (!contact.asset1_codes or contact.asset1_codes.count==0) and (!contact.asset2_codes or contact.asset2_codes.count==0) then
         errors.push("Record #{record_count.to_s}: Save contact #{contact_count.to_s} failed: no activation location for either party")
       else
         res=true
         create=false
         if no_create==true then
           #only save if both calls are registered
           uc=UserCallsign.find_by(callsign: contact.callsign2)
           if uc then 
             res=contact.valid?
             create=true
           else 
             puts "Skipping contact with unknown call: "+contact.callsign2 
             skip_count+=1
             create=false
           end
         else
           #always save
           res=contact.valid?
           create=true
         end
         if !res then 
           puts "IMPORT: save contact failed"
           errors.push("Record #{record_count.to_s}: Save contact #{contact_count.to_s} failed: "+contact.errors.messages.to_s)
         end
         if res and create then
           contacts[contact_count]=contact
           contacts_per_log[contact.log_id]+=1
           contact_count+=1
         end 
       end
     end  #end of parms.each 
  end #end of lines.each 
 
  good_logs=0 
  #create logs
  lc=0
  logs.each do |log|
    if contacts_per_log[lc]>0 and !invalid_log[lc] then 
      if errors.empty? or ignore_error then
        puts logs[lc].callsign1.inspect
        puts logs[lc].callsign1.length
        puts "SAVE: "+logs[lc].to_json
        if logs[lc].save then
           logs[lc].reload
           good_logs+=1
        else
           errors.push("FATAL: Save log #{lc.to_s} failed: "+logs[lc].errors.messages.to_s)
           invalid_log[lc]=true
        end
      else
        good_logs+=1
      end
    else
      puts "Skipping empty log: "+lc.to_s
    end
    lc+=1
  end

  #create contacts
  cc=0
  good_contacts=0
  contacts.each do |contact|
    if invalid_log[contact.log_id] then
      puts "Skipping contact #{cc.to_s} as log #{contact.log_id.to_s} invalid"
    else
      if errors.empty? or ignore_error then
        contact.log_id=logs[contact.log_id].id
        if contact.save  then
           good_contacts+=1
        else
           errors.push("FATAL: Save contact #{cc.to_s} failed: "+contact.errors.messages.to_s)
        end
      else
        good_contacts+=1
      end
    end
  end
  puts "IMPORT: clean exit"
  puts errors
  return {logs: logs, errors: errors, success: true, good_logs: good_logs, good_contacts: good_contacts}
end

def self.degs_from_deg_min_sec(value)
    negative=false
    value=value.gsub(/\r/,'').gsub(/\n/,'')
    if value[0].upcase=="S" or value[0].upcase=="W" then
       negative=true
       value=value[1..-1]
    end
    if value.match(/^\d{1,3} \d{1,3} \d{1}./) then
      deg=value.split(' ')[0]
      min=value.split(' ')[1]
      sec=value.split(' ')[2]
      pos=deg.to_f+(min.to_f/60)+(sec.to_f)/3600
    elsif value.match(/^\d{1,3} \d{1,3}\../) then
      deg=value.split(' ')[0]
      min=value.split(' ')[1]
      pos=deg.to_f+(min.to_f/60)
    else
      pos=value.to_f
    end
    if negative then pos=-pos end

  pos
end

def remove_suffix
  if self.callsign1['/'] then self.callsign1=Log.remove_suffix(self.callsign1) end
end

def self.remove_suffix(callsign)
  #try each part and choose longest
  theseg=nil
  maxlen=0
  segs=callsign.split('/')
  segs.each do |seg| 
    if seg.length>maxlen then theseg=seg;maxlen=seg.length end
  end
  theseg
end

end
