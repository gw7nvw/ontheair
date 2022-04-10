class Log < ActiveRecord::Base
  validates :callsign1,  presence: true, length: { maximum: 50 }

  belongs_to :createdBy, class_name: "User"
  before_save { self.check_codes_in_location }
  before_save { remove_suffix }
  after_save { update_contacts }
  #attr_accessor :asset_names

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
    self.add_child_codes
  end

  def add_child_codes
    self.asset_codes=self.get_all_asset_codes
  end

  def get_all_asset_codes
    codes=self.asset_codes
    newcodes=codes
    codes.each do |code|
      newcodes=newcodes+Asset.child_codes_from_parent(code)
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
      cle.loc_desc1=self.loc_desc1
      cle.is_qrp1=self.is_qrp1
      cle.power1=self.power1
      cle.is_portable1=self.is_portable1
      cle.x1=self.x1
      cle.y1=self.y1
      cle.location1=self.location1
      cle.convert_to_utc(User.find_by(callsign: cle.callsign1))
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

def self.import(filestr,user)

  logs=[]
  errors=[]

  count=0
  contactcount=0
  #check encoding
  if !filestr.valid_encoding? then
    filestr=filestr.encode("UTF-16be", :invalid=>:replace, :replace=>"?").encode('UTF-8')
  end

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

  lines.each do |line|
     contact=Contact.new
     protolog=Log.new
     if user then 
       contact.callsign1=user.callsign 
       protolog.callsign1=user.callsign
     end
     logid=nil
     timestr=nil
     contact.asset1_codes=[]
     contact.asset2_codes=[]
     contact.timezone=Timezone.find_by(name: "UTC").id
     #get date fro this line
     if line.upcase['QSO_DATE'] then
       #prefetch date
       date=line.upcase.split('<QSO_DATE')[1].split('>')[1][0..7]
       #prefetch assets codes
       locarr=[]

       line.split("<").each do |parm|
         if parm and parm.length>0 then
           key=parm.split('>')[0]
           key=key.split(':')[0]
           len=key.split(':')[1]
           value=parm.split('>')[1]
           if len then value=value[0..len-1] end
           puts "DEBUG: "+key.downcase
           case (key.downcase)
 
           when "station_callsign"
              callsign=value.strip
              #remove suffix
              if callsign['/'] then callsign=Log.remove_suffix(callsign) end
              protolog.callsign1=callsign
              contact.callsign1=callsign
           when "operator"
              callsign=value.strip
              #remove suffix
              if callsign['/'] then callsign=Log.remove_suffix(callsign) end
              protolog.callsign1=callsign
              contact.callsign1=callsign
           when "qso_date"
              protolog.date=value.strip
              contact.date=value.strip
           when "my_sota_ref"
              values=value.split(',')
              values.each do |val|
                protolog.asset_codes.push(val.strip)
                contact.asset1_codes.push(val.strip)
                protolog.is_portable1=true
                contact.is_portable1=true
              end
           when "my_sig_info"
              values=value.split(',')
              values.each do |val|
                protolog.asset_codes.push(val.strip)
                contact.asset1_codes.push(val.strip)
                protolog.is_portable1=true
                contact.is_portable1=true
              end
           when "comment"
                protolog.comments1=value.gsub(/\r/,'').gsub(/\n/,'')
                contact.comments1=value.gsub(/\r/,'').gsub(/\n/,'')
           when "my_antenna"
                protolog.antenna1=value.gsub(/\r/,'').gsub(/\n/,'')
                contact.antenna1=value.gsub(/\r/,'').gsub(/\n/,'')
           when "my_rig"
                protolog.transceiver1=value.gsub(/\r/,'').gsub(/\n/,'')
                contact.transceiver1=value.gsub(/\r/,'').gsub(/\n/,'')
           when "my_lat"
              pos=Log.degs_from_deg_min_sec(value)
              contact.y1=pos
              protolog.y1=pos
           when "my_long"
              pos=Log.degs_from_deg_min_sec(value)
              contact.x1=pos
              protolog.x1=pos
           when "my_city"
              contact.loc_desc1=value.strip
              protolog.loc_desc1=value.strip
           when "tx_pwr"
              contact.power1=value.strip
              protolog.power1=value.strip
              if value.strip.to_f<=10 then 
                contact.is_qrp1=true
                protolog.is_qrp1=true
              end
           when "band"
              contact.frequency=Contact.band_to_freq(value.strip)
           when "freq"
              contact.frequency=value.strip
           when "rst_sent"
              contact.signal2=value.strip
           when "rst_rcvd"
              contact.signal1=value.strip
           when "time_on"
              timestr=value.strip.gsub(':','')
           when "time_off"
              timestr=value.strip.gsub(':','')
           when "lat"
              pos=Log.degs_from_deg_min_sec(value)
              contact.y2=pos
           when "long"
              pos=Log.degs_from_deg_min_sec(value)
              contact.x2=pos
           when "mode"
              contact.mode=value.strip
           when "name"
              contact.name2=value.strip
           when "call"
              callsign=value.strip
              #remove suffix
              if callsign['/'] then callsign=Log.remove_suffix(callsign) end
              contact.callsign2=callsign
           when "qth"
              contact.loc_desc2=value.strip
           when "rx_pwr"
              contact.power2=value.strip
              if value.strip.to_f<=10 then 
                contact.is_qrp2=true
              end
           when "sota_ref"
              values=value.split(',')
              values.each do |val|
                contact.asset2_codes.push(val.strip)
                contact.is_portable2=true
              end
           when "sig_info"
              values=value.split(',')
              values.each do |val|
                contact.asset2_codes.push(val.strip)
                contact.is_portable2=true
              end
           end
          end #end of if
       end
       protolog.check_codes_in_location
       logs.each do |log|
          puts "IMPORT: testing"
          puts log.callsign1, protolog.callsign1, log.callsign1==protolog.callsign1
          puts log.date,protolog.date,log.date==protolog.date
          puts log.asset_codes,protolog.asset_codes,log.asset_codes == protolog.asset_codes
          if log.callsign1==protolog.callsign1 and log.date==protolog.date and log.asset_codes == protolog.asset_codes then 
                  logid=log.id
                  puts "IMPORT: matched"
          end
       end
       if !logid then
         puts "IMPORT: creating new log ("+count.to_s+")"
         count=logs.count
         lstr=protolog.to_json
         puts "DEBUG: "+lstr
         logs[count]=Log.new(JSON.parse(lstr))
         if logs[count].save then
           logs[count].reload
           logid=logs[count].id
         else
           errors.push("Create log #{count.to_s} failed: "+logs[count].errors.messages.to_s)
           return {logs: logs, errors: errors, success: false}
         end
       end 

       contact.log_id=logid
       puts "IMPORT: save contact"
       puts contact.to_json
       cstr=contact.to_json
       c=JSON.parse(cstr)
       contact=Contact.new(c)
       if timestr and protolog.date then contact.time=protolog.date.strftime("%Y-%m-%d")+" "+timestr[0..1]+":"+timestr[2..3] end
       contactcount+=1
       if !contact.date then
         puts "IMPORT: save contact failed"
         errors.push("Save contact #{contactcount.to_s} failed: no date/time")
#         return {logs: logs, errors: errors, success: false}
       elsif (!contact.asset1_codes or contact.asset1_codes.count==0) and (!contact.asset2_codes or contact.asset2_codes.count==0) then
         errors.push("Save contact #{contactcount.to_s} failed: no activation location for either party")
#         return {logs: logs, errors: errors, success: false}
       elsif !contact.save then 
         puts "IMPORT: save contact failed"
           errors.push("Save contact #{contactcount.to_s} failed: "+contact.errors.messages.to_s)
#           return {logs: logs, errors: errors, success: false}
       end
     end  #end of parms.each 
  end #end of lines.each 
   puts "IMPORT: clean exit"
   return {logs: logs, errors: errors, success: true}
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
