class User < ActiveRecord::Base
  serialize :score, Hash
  serialize :score_total, Hash
  serialize :activated_count, Hash
  serialize :activated_count_total, Hash
  serialize :chased_count, Hash
  serialize :chased_count_total, Hash

  attr_accessor :remeber_token, :activation_token, :reset_token

  before_save { if self.email then self.email = email.downcase end }
  before_save { if self.timezone==nil then self.timezone=Timezone.find_by(name: 'UTC').id end }
  before_save { self.callsign = callsign.upcase }
  
  before_save { if self.pin==nil or self.pin.length<4 then self.pin=self.callsign.chars.shuffle[0..3].join end; self.pin=self.pin[0..3] }
  before_create :create_remember_token

  VALID_NAME_REGEX = /\A[a-zA-Z\d\s]*\z/i
  validates :callsign,  presence: true, length: { maximum: 50 },
                uniqueness: { case_sensitive: false }, format: { with: VALID_NAME_REGEX }

  VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i
  has_secure_password

  def User.new_token
    SecureRandom.urlsafe_base64
  end

  def User.digest(token)
    Digest::SHA1.hexdigest(token.to_s)
  end

def authenticated?(attribute, token)
     digest = send("#{attribute}_digest")
    return false if digest.nil?
    Digest::SHA1.hexdigest(token.to_s)==digest
  end

  # Activates an account.
  def activate
    update_attribute(:activated,    true)
    update_attribute(:activated_at, Time.zone.now)
  end

 def has_award(award_id)
   uas=AwardUserLink.find_by_sql [ " select * from award_user_links where user_id = "+self.id.to_s+" and award_id = "+award_id.to_s ]
   if uas and uas.count>0 then true else false end
 end

 def timezonename
   timezonename=""
   if self.timezone!="" then
     tz=Timezone.find_by_id(self.timezone)
     if tz then timezonename=tz.name end
   end
   timezonename
 end

  def self.find_by_full_callsign(callsign)
    if callsign and callsign.length>0 then 
      endpos=callsign.index("/")
      if endpos then callsign=callsign[0..endpos-1] end
      user=User.find_by(callsign: callsign)
    else 
      user=nil
    end
    user
  end

  # Sends activation email.
  def send_activation_email
    UserMailer.account_activation(self).deliver
  end

  # Sets the password reset attributes.
  def create_reset_digest
    self.reset_token = User.new_token
    update_attribute(:reset_digest,  User.digest(reset_token))
    update_attribute(:reset_sent_at, Time.zone.now)
  end

  # Sends password reset email.
  def send_password_reset_email
    UserMailer.password_reset(self).deliver
  end

 # Sends youve been signed up choose a password email.
  def send_new_password_email
    UserMailer.new_password(self).deliver
  end

  # Returns true if a password reset has expired.
  def password_reset_expired?
    reset_sent_at < 2.hours.ago
  end

  def create_activation_digest
    self.activation_token = User.new_token
    self.activation_digest = User.digest(activation_token)
  end

  def contacts
      contacts=Contact.find_by_sql [ "select * from contacts where callsign1='"+self.callsign+"' or callsign2='"+self.callsign+"' order by date, time"]
  end
  def logs
      logs=Log.find_by_sql [ "select * from logs where callsign1='"+self.callsign+"' order by date"]
  end

  def filter_contacts(contacts,user_qrp, contact_qrp)
    fc=[]
    contacts.each do |c|
     if contact_qrp then
       if c.is_qrp1 and c.is_qrp2 then fc.push(c) end
     elsif user_qrp
       if (c.callsign1==self.callsign and c.is_qrp1) or
          (c.callsign2==self.callsign and c.is_qrp2) then
              fc.push(c)
       end
     else
       fc.push(c)
     end
    end
    fc
  end

  def contacts_filtered(user_qrp, contact_qrp)
    contacts=self.contacts
    fc=filter_contacts(contacts,user_qrp, contact_qrp)
    fc 
  end

  def self.users_with_assets
    callsigns=[]
    contacts=Contact.where("asset1_codes is not null or asset2_codes is not null")
    contacts.each do |c|
      callsigns.push(c.callsign1) 
      callsigns.push(c.callsign2) 
    end
    users=User.where(callsign: callsigns.uniq)
  end

  def self.update_scores
    users=User.all
    users.each do |user|
       user.update_score
    end
  end

  def update_score
    scores=self.assets_count_all
    ats=AssetType.where(keep_score: true)
    qrp=AssetType.new
    qrp.name="qrp"
    ats << qrp
    ats.each do |asset_type|
       self.score[asset_type.name]=scores[:bagged_count][asset_type.name]
       self.score_total[asset_type.name]=scores[:bagged_count_total][asset_type.name]
       self.activated_count[asset_type.name]=scores[:activated_count][asset_type.name]
       self.activated_count_total[asset_type.name]=scores[:activated_count_total][asset_type.name]
       self.chased_count[asset_type.name]=scores[:chased_count][asset_type.name]
       self.chased_count_total[asset_type.name]=scores[:chased_count_total][asset_type.name]
    end

    self.score["p2p"]=self.get_p2p_all.count
    success=self.save
  end

  def get_p2p_all
    #all activations I make that are ZLOTA to /P
    p2p=[]
    contacts1=Contact.find_by_sql [ "select c1.time as time, c1.date as date, c1.id as id, c1.callsign1 as callsign1, c1.callsign2 as callsign2, unnest(c1.asset1_codes) as asset1_code, asset2_code from contacts c1 join (select id, unnest(asset2_codes) as asset2_code from contacts) c2 on c2.id=c1.id where c1.callsign1='#{self.callsign}'; " ]
    contacts2=Contact.find_by_sql [ "select c1.time as time, c1.date as date, c1.id as id, c1.callsign1 as callsign1, c1.callsign2 as callsign2, unnest(c1.asset1_codes) as asset1_code, asset2_code from contacts c1 join (select id, unnest(asset2_codes) as asset2_code from contacts) c2 on c2.id=c1.id where c1.callsign2='#{self.callsign}'; " ]

    contacts1.each do |c|
        a=Asset.find_by(code: c.asset1_code)
        if !a then a=Asset.find_by(code: c.asset2_code) end
        if (a and a.type.keep_score) and c.asset1_code!="" and c.asset2_code!="" then
          p2p.push(c.asset1_code.split(' ')[0]+" "+c.asset2_code.split(' ')[0]+" "+c.localdate(nil).to_s)
        end
    end
    contacts2.each do |c|
        a=Asset.find_by(code: c.asset2_code)
        if !a then a=Asset.find_by(code: c.asset1_code) end
        if (a and a.type.keep_score) and c.asset1_code!="" and c.asset2_code!="" then
          p2p.push(c.asset2_code.split(' ')[0]+" "+c.asset1_code.split(' ')[0]+" "+c.localdate(nil).to_s)
        end
      end 
    p2p.uniq
  end


  def assets(at)
    assets=self.assets_filtered(at,false, false)
  end


  def assets_count_all

   ats=AssetType.where("name != 'all'")
   qrp=AssetType.new
   qrp.name='qrp'
   ats << qrp

   activated_count_total={}
   activated_count={}
   chased_count_total={}
   chased_count={}
   bagged_count_total={}
   bagged_count={}

   cs=self.assets_all

   ats.each do |at|
     activated_count[at.name]=cs[:a][at.name].uniq.count
     activated_count_total[at.name]=cs[:at][at.name].uniq.count
     chased_count[at.name]=cs[:c][at.name].uniq.count
     chased_count_total[at.name]=cs[:ct][at.name].uniq.count
     bagged_count[at.name]=(cs[:a][at.name]+cs[:c][at.name]).uniq.count
     bagged_count_total[at.name]=(cs[:at][at.name]+cs[:ct][at.name]).uniq.count
   end
   results={activated_count: activated_count, activated_count_total: activated_count_total, chased_count: chased_count, chased_count_total: chased_count_total, bagged_count: bagged_count, bagged_count_total: bagged_count_total}
end

  def assets_all

   ats=AssetType.where("name != 'all'")
   qrp=AssetType.new
   qrp.name='qrp'
   ats << qrp
   activated_total={}
   activated={}
   chased_total={}
   chased={}
   qrp_activated=[]
   qrp_chased=[]
   qrp_activated_total=[]
   qrp_chased_total=[]

   ats.each do |at|
     activated[at.name]=[]
     activated_total[at.name]=[]
     chased[at.name]=[]
     chased_total[at.name]=[]
   end

   contacts=Contact.where(callsign1: self.callsign)
   contacts.each do |c|
     if c.date then 
       if c.asset1_codes then c.asset1_codes.each do |code|
         a=Asset.find_by(code: code)
         if (a and a.is_active and !(a.minor==true)) then
           if a.type.keep_score==true and c.is_qrp1==true then 
             activated_total['qrp'].push(a.code+" "+c.date.strftime('%Y')) 
               activated['qrp'].push(a.code)
           end
           activated_total[a.asset_type].push(a.code+" "+c.date.strftime('%Y'))
           activated[a.asset_type].push(a.code)
         end
       end end
       if c.asset2_codes then c.asset2_codes.each do |code|
         a=Asset.find_by(code: code)
         if (a and a.is_active and !(a.minor==true)) then
           if a.type.keep_score==true and c.is_qrp1==true then 
             chased_total['qrp'].push(a.code+" "+c.localdate(nil).to_s) 
             chased['qrp'].push(a.code) 
           end
           chased_total[a.asset_type].push(a.code+" "+c.localdate(nil).to_s)
           chased[a.asset_type].push(a.code)
         end
       end end
     end
   end
   contacts=Contact.where(callsign2: self.callsign)
   contacts.each do |c|
     if c.asset2_codes then c.asset2_codes.each do |code|
       a=Asset.find_by(code: code)
       if (a and a.is_active and !(a.minor==true)) then
         #Activatons count once per year
         if a.type.keep_score==true and c.is_qrp2==true then 
           activated_total['qrp'].push(a.code+" "+c.date.strftime('%Y')) 
           activated['qrp'].push(a.code) 
         end

         activated_total[a.asset_type].push(a.code+" "+c.date.strftime('%Y'))
         activated[a.asset_type].push(a.code)
       end
     end end
     if c.asset1_codes then c.asset1_codes.each do |code|
       a=Asset.find_by(code: code)
       if (a and a.is_active and !(a.minor==true)) then
         if a.type.keep_score==true and c.is_qrp2==true then 
           chased_total['qrp'].push(a.code+" "+c.localdate(nil).to_s) 
           chased['qrp'].push(a.code) 
         end

         #Chases count once per day
         chased_total[a.asset_type].push(a.code+" "+c.localdate(nil).to_s)
         chased[a.asset_type].push(a.code)
       end
     end end
   end
  {a: activated, at: activated_total, c: chased, ct: chased_total}

  end

  def assets_filtered(at, user_qrp, contact_qrp)
   assets=[]
   contacts=self.contacts_filtered(user_qrp, contact_qrp)
   contacts.each do |c|
     c.asset1_codes.each do |code|
       a=Asset.find_by(code: code)
       if (a and a.asset_type==at) then assets.push(a.code) end
     end
     c.asset2_codes.each do |code|
       a=Asset.find_by(code: code)
       if (a and a.asset_type==at) then assets.push(a.code) end
     end
   end


   assets=Asset.where(code: assets).order(:name)
  end


  def wwff_logs(resubmit)
   if resubmit==true then resubmit_str="" else resubmit_str=" and submitted_to_wwff is not true" end
   wwff_logs=[]
   puts "resubmit: "+resubmit_str
   contacts1=Contact.find_by_sql [ "select asset1_codes  from (select distinct unnest(asset1_codes) as asset1_codes  from contacts where callsign1 = '"+self.callsign+"'"+resubmit_str+") as sq where asset1_codes  like 'ZLP%%'" ]
   contacts2=Contact.find_by_sql [ "select asset1_codes  from (select distinct unnest(asset1_codes) as asset1_codes  from contacts where callsign1 = '"+self.callsign+"'"+resubmit_str+") as sq where asset1_codes  like 'ZLFF-%%'" ]

   parks=[]
   contacts1.each do |contact|
       p=Asset.find_by(code: contact.asset1_codes)
       pp=p.linked_assets_by_type("wwff park")
       if pp and pp.count>0 then
         parks.push(wwffpark: pp.first.code, name: pp.first.name)
       end
   end
   contacts2.each do |contact|
       pp=Asset.find_by(code: contact.asset1_codes)
       p=pp.linked_assets_by_type("park")
       if p and p.count>0 then
         parks.push(wwffpark: pp.code, name: pp.name)
       end
   end
   parks=parks.uniq 

   parks.each do |park|
     pp=Asset.find_by(code: park[:wwffpark]);
     dps=pp.linked_assets_by_type("park");
     dpcodes=dps.map{|dp| dp.code}
     contacts1=Contact.where(" callsign1 = ? and (? = ANY(asset1_codes) or (array[?]::varchar[] && asset1_codes))"+resubmit_str, self.callsign, park[:wwffpark], dpcodes)

     contact_count=contacts1.count
     callsigns=[]
     contacts=[]
     contacts1.each do |contact| callsigns.push({callsign: contact.callsign2,date: contact.date.to_date}) end
     callsigns=callsigns.uniq
     contacts_count=callsigns.count

     callsigns.each do |cs|


       contacts1=Contact.where('callsign1= ? and callsign2 = ? and date >= ? and date < ? and ((array[?]::varchar[] && asset1_codes) or ? = ANY(asset1_codes))'+resubmit_str,  self.callsign,  cs[:callsign], cs[:date].beginning_of_day,cs[:date].end_of_day, dpcodes, park[:wwffpark])
       if contacts1 and contacts1.count>0 then 
         contacts.push(contacts1.first) 
         if contacts1.count>1 then puts "Dropping "+(contacts1.count-1).to_s+" "+contacts1.first.callsign1+" "+contacts1.first.callsign2+" "+contacts1.first.date.to_date.to_s end
       end
     end
     
     wwff_logs.push({park: park, count: contacts_count, contacts: contacts.sort_by{|c| c.date}})
   end
  wwff_logs
  end

  def sota_logs
   sota_logs=[]
   contacts1=Contact.where(callsign1: self.callsign)

   summits=[]
   contacts1.each do |contact|
     assets=contact.activator_asset_links
     assets.each do |a|
       if a and a.asset_type=="summit" then
         summits.push(a)
       end
     end
   end
   summits=summits.uniq

   summits.each do |summit| 
     contacts1=Contact.where("callsign1 = ? and ? =ANY(asset1_codes)", self.callsign, summit.code )
     dates=[]
     contacts1.each do |contact|
       dates.push(contact.date.to_date)
     end
     dates=dates.uniq
      
     dates.each do |date| 
       contacts1=Contact.where("callsign1 = ? and ? = ANY(asset1_codes) and date >= ? and date < ?", self.callsign,  summit.code, date.beginning_of_day,date.end_of_day)
       contact_count=contacts1.count
       contacts=[]
       contacts1.each do |contact| contacts.push(contact) end
       sota_logs.push({summit: summit, date: date, count: contact_count, contacts: contacts.sort_by{|c| c.date}})  
     end
   end 
  sota_logs
  end

  def pota_logs
   pota_logs=[]

   contacts1=Contact.find_by_sql [ "select asset1_codes  from (select distinct unnest(asset1_codes) as asset1_codes  from contacts where callsign1 = '"+self.callsign+"') as sq where asset1_codes  like 'ZLP%%'" ]
   contacts2=Contact.find_by_sql [ "select asset1_codes  from (select distinct unnest(asset1_codes) as asset1_codes  from contacts where callsign1 = '"+self.callsign+"') as sq where asset1_codes  like 'ZL-%%'" ]

   parks=[]
   contacts1.each do |contact|
       p=Asset.find_by(code: contact.asset1_codes)
       pp=p.linked_assets_by_type("pota park")
       if pp and pp.count>0 then 
         parks.push(potapark: pp.first.code, name: pp.first.name)
       end
   end
   contacts2.each do |contact|
       pp=Asset.find_by(code: contact.asset1_codes)
       p=pp.linked_assets_by_type("park")
       if p and p.count>0 then 
         parks.push(potapark: pp.code, name: pp.name)
       end
   end
   parks=parks.uniq 

   parks.each do |park| 
     pp=Asset.find_by(code: park[:potapark]);
     dps=pp.linked_assets_by_type("park");
     dpcodes=dps.map{|dp| dp.code}
     puts dpcodes;
     contacts1=Contact.where(" callsign1 = ? and (? = ANY(asset1_codes) or (array[?]::varchar[] && asset1_codes))", self.callsign, park[:potapark], dpcodes)
 
     dates=[]
     contacts1.each do |contact|
       dates.push(contact.date.to_date)
     end
     dates=dates.uniq
      
     dates.each do |date| 
       contacts1=Contact.where(" callsign1 = ? and ((array[?]::varchar[] && asset1_codes) or ? = ANY(asset1_codes)) and date >= ? and date < ? ", self.callsign, dpcodes, park[:potapark], date.beginning_of_day,date.end_of_day)
       contact_count=contacts1.count
       contacts=[]
       contacts1.each do |contact| contacts.push(contact) end
       pota_logs.push({park: park, date: date, count: contact_count, contacts: contacts.sort_by{|c| c.date}})  
     end
   end 
  pota_logs
  end


  private

    def create_remember_token
      self.remember_token = User.digest(User.new_token)
    end

    def downcase_email
      self.email = email.downcase
    end


end
