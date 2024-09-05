class Log < ActiveRecord::Base
  validates :callsign1,  presence: true, length: { maximum: 50 }

  belongs_to :createdBy, class_name: "User"
  before_save { self.before_save_actions }
  after_save { self.update_contacts }

  def before_save_actions
    self.remove_call_suffix
    self.callsign1=UserCallsign.clean(self.callsign1)
    self.add_user_ids
    self.check_codes_in_location
    location=self.get_most_accurate_location
    self.add_child_codes(location[:asset])
    self.update_classes
  end

  #################################
  # CALCULATED PARAMETERS 
  #################################

  def user
    User.find(self.user1_id)
  end

  def assets
    if self.asset_codes then Asset.where(code: self.asset_codes) else [] end
  end 
 
  def asset_names
    asset_names=self.assets.map{|asset| asset.name}
    if !asset_names then asset_names="" end
    asset_names
  end

  def asset_code_names
    if self.asset_codes then asset_names=self.asset_codes.map{|ac| asset=Asset.assets_from_code(ac).first; if asset then "["+asset[:code]+"] "+asset[:name] else "" end} else asset_names=[] end
    if !asset_names then asset_names=[] end
    asset_names
  end

  def contacts
    if self.id and self.id>0 then
      cs=Contact.where(log_id: self.id)
    else 
      nil
    end
    cs
  end

  #uses contact time by preference as log date will be fore 00:00UTC which may be 
  #in a different local day
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


  #################################
  # BEFORE SAVE ACTIONS
  #################################
  def add_user_ids
    #look up callsign1 at contact.time
    user1=User.find_by_callsign_date(self.callsign1, self.date, true)
    if user1 then self.user1_id=user1.id end
  end

  def remove_call_suffix
    if self.callsign1['/'] then self.callsign1=User.remove_call_suffix(self.callsign1) end
  end

  #update asset_classes array to show asset type for all asset_codes - in order
  def update_classes
    asset_classes=[]
    self.asset_codes.each do |code|
      asset=Asset.assets_from_code(code)
      if asset and asset.count>0 then
        asset_classes.push(asset.first[:type])
      end
    end
    self.asset_classes=asset_classes
  end


  def check_codes_in_location
    if self.asset_codes==nil or self.asset_codes==[] or self.asset_codes==[""] then
      self.asset_codes=Asset.check_codes_in_text(self.loc_desc1)
    end
  end

  def get_most_accurate_location(force = false)
    location={location: self.location1, source: self.loc_source, asset: nil}

    if self.location1==nil then self.loc_source=nil end

    #for anything other than a user specified location
    if self.loc_source!='user' then
      # only overwrite a location when asked to
      if self.location1 and force==true then self.loc_source=nil; self.location1=nil end

      #lookup location for asset by finding most accurate asset location
      location=Asset.get_most_accurate_location(self.asset_codes, self.loc_source)
      self.loc_source=location[:source]
      self.location1=location[:location]
    end
    location
  end

  def add_child_codes(asset)
    self.asset_codes=Asset.find_master_codes(self.asset_codes)
    if !self.do_not_lookup==true then
      self.asset_codes=self.get_all_asset_codes(asset)
    end
  end

  def get_all_asset_codes(asset)
    codes=self.asset_codes
    newcodes=codes
    # Add ZL child codes by lcoation
    if self.location1 then newcodes=newcodes+Asset.child_codes_from_location(self.location1, asset) end
    # Add VK child codes using lookup table
    codes.each do |code|
      newcodes=newcodes+VkAsset.child_codes_from_parent(code)
    end
    newcodes.uniq
  end

  def update_contacts
    contacts=Contact.where(:log_id => self.id)
    contacts.each do |cle|
      cle.callsign1=self.callsign1
      cle.date=self.date
      #pick up changes in date and apply to time
      cle.time=Time.iso8601(self.date.strftime("%Y-%m-%d")+"T"+cle.time.strftime("%H:%M:%SZ"))
      cle.loc_desc1=self.loc_desc1
      cle.is_qrp1=self.is_qrp1
      cle.power1=self.power1
      cle.is_portable1=self.is_portable1
      cle.x1=self.x1
      cle.y1=self.y1
      cle.location1=self.location1
      cle.asset1_codes=self.asset_codes
      cle.save
    end
  end




  ####################################################################
  # LOG FILE IMPORTS
  ####################################################################

  def self.import(filetype, currentuser, filestr,user,default_callsign=nil,default_location=nil,no_create=false, ignore_error=false,  do_not_lookup=false)
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
      logger.info "Invalid encoding repaired"
    end
 
    #force to ASCII. HAMRS seems to include broken UTF8 which above check fails to fix
    #TODO: need a better fix that doesn't lose extended characters.
    filestr =filestr.encode('ASCII', :invalid=>:replace, :undef=>:replace, :replace=>"?").encode('UTF-8')

    #extract array of contacts from the log as 'lines'
    if filetype=='adif' then
      lines=Log.prepare_adif(filestr) 
    else
      lines=filestr.lines
    end
  
    record_count=0
    skip_count=0
    lines.each do |line|
       contact=Contact.new
       protolog=Log.new

       #apply any default values speficied in the upload log screen
       protolog.do_not_lookup=do_not_lookup
       if user and default_callsign then 
         contact.callsign1=default_callsign.encode('UTF-8')
         protolog.callsign1=default_callsign.encode('UTF-8')
       end
       logid=nil
       contact.asset1_codes=[]
       contact.asset2_codes=[]
       if default_location and default_location.length>0 and default_location.strip.length>0 then
         protolog.asset_codes.push(default_location.strip.upcase)
         contact.asset1_codes.push(default_location.strip.upcase)
       end
  
       contact.timezone=Timezone.find_by(name: "UTC").id
       #if it is a valid contact it will have one of these two fields
       #ignore anything that doesn't	
       if Log.valid_logfile_entry(line,filetype) then 

         #parse this record
         if filetype=='adif' then
           protolog, contact, timestring = Log.parse_adif_record(line, protolog, contact) 
         else
           protolog, contact, timestring = Log.parse_csv_record(line, protolog, contact)
         end

         record_count+=1
         #extract asset_codes from location field
         protolog.check_codes_in_location

         #check if this proto-log matches an existing log for this file
         lc=0
         logs.each do |log|
            if log.callsign1==protolog.callsign1 and log.date==protolog.date and (protolog.asset_codes-log.asset_codes).empty? then 
              logid=lc
              logger.info "IMPORT: matched existing log: #{lc.to_s}"
            end  
            lc+=1
         end

         #if not, create a new log from the proto-log
         if logid==nil then
           logger.info "IMPORT: creating new log ("+log_count.to_s+")"
           log_count=logs.count
           lstr=protolog.to_json
           invalid_log[log_count]=true
           logs[log_count]=Log.new(JSON.parse(lstr))

           #check if user has permissions to create this log and if log is valid
           loguser=User.find_by_callsign_date(logs[log_count].callsign1,logs[log_count].date)
           if loguser and (loguser.id==user.id or currentuser.is_admin) then
             if logs[log_count].valid? then
               logger.info "Valid log "+log_count.to_s    
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
    
         #apply this contact to the log it belongs to 
         contact.log_id=logid

         #create a new contact from the log entry data
         cstr=contact.to_json
         c=JSON.parse(cstr)
         contact=Contact.new(c)
   
         #get time/date into correct format
         timestring=(timestring||"").rjust(4,'0')

         if timestring and protolog.date then contact.time=protolog.date.strftime("%Y-%m-%d")+" "+timestring[0..1]+":"+timestring[2..3] end

         #validate contact
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
               skip_count+=1
               create=false
             end
           else
             #always save
             res=contact.valid?
             create=true
           end
           if !res then 
             logger.info "IMPORT: save contact failed"
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
          logger.info logs[lc].callsign1.inspect
          logger.info logs[lc].callsign1.length
          logger.info "SAVE: "+logs[lc].to_json
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
        logger.info "Skipping empty log: "+lc.to_s
      end
      lc+=1
    end
  
    #create contacts
    cc=0
    good_contacts=0
    contacts.each do |contact|
      if invalid_log[contact.log_id] then
        logger.info "Skipping contact #{cc.to_s} as log #{contact.log_id.to_s} invalid"
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
    logger.info "IMPORT: clean exit"
    logger.info errors
    logger.info logs.to_json
    return {logs: logs.select{|log| log.id!=nil}, errors: errors, success: true, good_logs: good_logs, good_contacts: good_contacts}
  end
 
  #####################################################################################
  # HELPERS
  #####################################################################################

  def update_qualified
    qualified=[]
    self.asset_classes.each do |ac|
      at=AssetType.find_by(name: ac)
      unique_contacts=Contact.find_by_sql [" select distinct callsign2, mode, band from contacts where log_id=#{self.id};"]
      if unique_contacts.count>=at.min_qso then 
        asset_qualified=true
      else
        asset_qualified=false
      end 
      qualified.push(asset_qualified)
    end

    self.qualified=qualified
    self.update_column(:qualified, qualified)
  end

  def self.valid_logfile_entry(line,filetype)
    if filetype=='adif' then
      valid=if line.upcase['QSO_DATE'] or line.upcase['TIME_ON'] then true else false end
    else
      valid=line[0..1]=='V2'
    end
    valid
  end 

  def self.prepare_adif(filestr)
    #Read ADIF 
    # remove header
    if filestr["<EOH>"] or filestr["<eoh>"] then
      logbody=filestr.split(/<EOH>|<eoh>/)[1]
    else
      logbody=filestr
    end
  
    # check for <eor>
    if logbody["<eor>"] or logbody["<EOR>"] then 
       #each record terminated by <eor>
       lines=logbody.split(/<EOR>|<eor>/) 
    else
       #if no <eor> then assume one record per line
       lines=logbody.lines
    end
    lines
  end

  def self.parse_csv_record(line, protolog, contact)
    timestr=nil
    #split by ',' 
    #TODO: need way of doing this that respects ',' in quotes (does not split quoted text)
    fields=line.split(',')

    #my calls
    value=fields[1]
    if value and value.length>0 and value.strip.length>0 then
       callsign=value.strip.upcase
       #remove suffix
       if callsign['/'] then callsign=User.remove_call_suffix(callsign) end
       protolog.callsign1=callsign
       contact.callsign1=callsign
    end

    #date
    value=fields[3]
    if value and value.length>0 and value.strip.length>0 then
       parts=value.strip.split('/')
       if parts[0].length==2 then #assume dd-mm-yy as per iPnP
         if parts[2].length==2 then #assume dd-mm-yy as per iPnP
           protolog.date='20'+parts[2]+'/'+parts[1]+'/'+parts[0]
         else
           protolog.date=parts[2]+'/'+parts[1]+'/'+parts[0]
         end
         contact.date=protolog.date
       else #assume yyyy-mm-dd as per SOTA
         protolog.date=value.strip
         contact.date=value.strip
       end
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
       contact.frequency=value.strip.gsub(/[GMk]Hz/,"")
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
      if callsign['/'] then callsign=User.remove_call_suffix(callsign) end
      contact.callsign2=callsign
    end

    #other location
    value=fields[8]
    if value and value.length>0 then
      values=value.split(';')
      values.each do |val|
        val=Asset.correct_separators(val.strip)
        contact.asset2_codes.push(val)
        contact.is_portable2=true
      end
    end
    #comment
    value=fields[9]
    if value and value.length>0 then
      contact.comments1=value.strip #strip to not pick up and CRLF stuff from end of line
    end

    return protolog, contact, timestr
  end

  def self.parse_adif_record(line, protolog, contact)
    timestr=nil

    line.split("<").each do |parm|
      if parm and parm.length>0 then
        key=parm.split('>')[0]
        len=key.split(':')[1]
        key=key.split(':')[0]
        value=parm.split('>')[1]
        if value then
        logger.info "value: "+value.to_s
        logger.info "length: "+value.length.to_s
        logger.info "len: "+len.to_s
        logger.info "key: "+key
        end

        if len and len.to_i>0 then 
          logger.info "Truncate"
          value=value[0..(len.to_i)-1] 
          logger.info "length: "+value.length.to_s
        end
        logger.info "DEBUG: "+key.downcase
        case (key.downcase)

        when "station_callsign"
           if value and value.length>0 and value.strip.length>0 then
             callsign=value.strip.upcase
             #remove suffix
             if callsign['/'] then callsign=User.remove_call_suffix(callsign) end
             protolog.callsign1=callsign
             contact.callsign1=callsign
           end
        when "operator"
           if value and value.length>0 and value.strip.length>0 then
             callsign=value.strip.upcase
             #remove suffix
             if callsign['/'] then callsign=User.remove_call_suffix(callsign) end
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
               contact.frequency=Contact.frequency_from_band(value.strip)
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
             if callsign['/'] then callsign=User.remove_call_suffix(callsign) end
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
    return protolog, contact, timestr
  end


  #Convert [NSWE]<deg> <min> <sec.##> to +/-<deg.##> 
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
 
  #one-off to apply clsses to all logs 
  def self.update_all_classes
    logs=Log.all
    logs.each do |log|
      puts log.id
      log.update_classes
      log.update_column(:asset_classes, log.asset_classes)
    end     
  end 
  #one-off to add qualifed to all logs
  def self.update_qualified
    logs=Log.all
    logs.each do |log|
      puts log.id
      log.update_qualified
      #log.update_column(:qualifed, log.qualifed)
    end     
  end 
end
