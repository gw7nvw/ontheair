class User < ActiveRecord::Base
  serialize :score, Hash
  serialize :score_total, Hash
  serialize :activated_count, Hash
  serialize :activated_count_total, Hash
  serialize :chased_count, Hash
  serialize :chased_count_total, Hash

  attr_accessor :remeber_token, :activation_token, :reset_token

  before_save { if email then self.email = email.downcase end }
  before_save { if timezone==nil then self.timezone=Timezone.first.id end }
  before_save { self.callsign = callsign.upcase }
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
    endpos=callsign.index("/")
    if endpos then callsign=callsign[0..endpos-1] end
    user=User.find_by(callsign: callsign)
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

  def contacts_filtered(user_qrp, contact_qrp)
    fc=[]
    contacts=self.contacts
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
  end

  def self.users_with_assets
    callsigns=[]
    contacts=Contact.where("asset1_codes is not null or asset2_codes is not null")
    contacts.each do |c|
      callsigns.push(c.callsign1) 
      callsigns.push(c.callsign2) 
    end
    users=User.where(callsign: callsigns)
  end

  def self.update_scores
    users=User.all
    users.each do |user|
       user.update_score
    end
  end

  def update_score
    AssetType.where(keep_score: true).each do |asset_type|
       self.score[asset_type.name]=self.assets_count_filtered(asset_type.name,false,false,false)
       self.score_total[asset_type.name]=self.assets_count_filtered(asset_type.name,false,false,true)
       self.activated_count[asset_type.name]=self.assets_activated_count(asset_type.name,false)
       self.activated_count_total[asset_type.name]=self.assets_activated_count(asset_type.name,true)
       self.chased_count[asset_type.name]=self.assets_chased_count(asset_type.name,false)
       self.chased_count_total[asset_type.name]=self.assets_chased_count(asset_type.name,true)
     end
     success=self.save
  end

  def assets(at)
    assets=self.assets_filtered(at,false, false)
  end

  def assets_activated_count(at,revisits)
   assets=[]
   contacts=self.contacts_filtered(nil, nil)
   contacts.each do |c|
     c.asset1_codes.each do |code|
       a=Asset.find_by(code: code)
       if (a and a.asset_type==at and c.callsign1==self.callsign) then 
         if revisits then assets.push(a.code+" "+c.localdate(nil).to_s)
         else assets.push(a.code) end
       end
     end
     c.asset2_codes.each do |code|
       a=Asset.find_by(code: code)
       if (a and a.asset_type==at and c.callsign2==self.callsign) then 
         if revisits then assets.push(a.code+" "+c.localdate(nil).to_s)
         else assets.push(a.code) end
       end
     end
   end
   assets.uniq.count
  end

  def assets_chased_count(at,revisits)
   assets=[]
   contacts=self.contacts_filtered(nil, nil)
   contacts.each do |c|
     c.asset1_codes.each do |code|
       a=Asset.find_by(code: code)
       if (a and a.asset_type==at and c.callsign2==self.callsign) then 
         if revisits then assets.push(a.code+" "+c.localdate(nil).to_s)
         else assets.push(a.code) end
       end
     end
     c.asset2_codes.each do |code|
       a=Asset.find_by(code: code)
       if (a and a.asset_type==at and c.callsign1==self.callsign) then 
         if revisits then assets.push(a.code+" "+c.localdate(nil).to_s)
         else assets.push(a.code) end
       end
     end
   end
   assets.uniq.count
  end

  def assets_count_filtered(at,user_qrp, contact_qrp, revisits)
   assets=[]
   contacts=self.contacts_filtered(user_qrp, contact_qrp)
   contacts.each do |c|
     c.asset1_codes.each do |code|
       a=Asset.find_by(code: code)
       if (a and a.asset_type==at) then 
         if revisits then assets.push(a.code+" "+c.localdate(nil).to_s)
         else assets.push(a.code) end
       end
     end
     c.asset2_codes.each do |code|
       a=Asset.find_by(code: code)
       if (a and a.asset_type==at) then 
         if revisits then assets.push(a.code+" "+c.localdate(nil).to_s)
         else assets.push(a.code) end
       end
     end
   end
   assets.uniq.count
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


  def generate_membership_request
    as=AdminSettings.first
    if as then 
      qrpnz_email=as.qrpnz_email 
    
      if self.is_active and self.email then 
          puts "We should generate an email to "+qrpnz_email+" requesting membership"
          UserMailer.membership_request(self,qrpnz_email).deliver 
          puts "We should generate an email to "+self.callsign+" confirming membership request"
          UserMailer.membership_request_notification(self,qrpnz_email).deliver 
      end
    else
      puts "ERROR: No QRPNZ admin email defined."
    end
  end

  def wwff_logs
   wwff_logs=[]
   contacts1=Contact.find_by_sql [ "select asset1_codes  from (select distinct unnest(asset1_codes) as asset1_codes  from contacts where callsign1 = '"+self.callsign+"') as sq where asset1_codes  like 'ZLP%%'" ]
   contacts2=Contact.find_by_sql [ "select asset1_codes  from (select distinct unnest(asset1_codes) as asset1_codes  from contacts where callsign1 = '"+self.callsign+"') as sq where asset1_codes  like 'ZLFF-%%'" ]

   parks=[]
   contacts1.each do |contact|
       p=Asset.find_by(code: contact.asset1_codes)
       pp=p.linked_assets_by_type("wwff park")
       if pp and pp.count>0 then
         parks.push(docpark: p.code, wwffpark: pp.first.code, name: pp.first.name)
       end
   end
   contacts2.each do |contact|
       pp=Asset.find_by(code: contact.asset1_codes)
       p=pp.linked_assets_by_type("park")
       if p and p.count>0 then
         parks.push(docpark: p.first.code, wwffpark: pp.code, name: pp.name)
       end
   end
   parks=parks.uniq 

   parks.each do |park|
     contacts1=Contact.where('callsign1 = ? and (? = ANY(asset1_codes) or ?= ANY(asset1_codes))',self.callsign, park[:docpark], park[:wwffpark])

     contact_count=contacts1.count
     callsigns=[]
     contacts=[]
     contacts1.each do |contact| callsigns.push({callsign: contact.callsign2,date: contact.date.to_date}) end
     callsigns=callsigns.uniq
     contacts_count=callsigns.count

     callsigns.each do |cs|


       contacts1=Contact.where('callsign1= ? and callsign2 = ? and date >= ? and date < ? and (? = ANY(asset1_codes) or ? = ANY(asset1_codes))',  self.callsign,  cs[:callsign], cs[:date].beginning_of_day,cs[:date].end_of_day, park[:docpark], park[:wwffpark])
       if contacts1 and contacts1.count>0 then 
         contacts.push(contacts1.first) 
         if contacts1.count>1 then puts "Dropping "+(contacts1.count-1).to_s+" "+contacts1.first.callsign1+" "+contacts1.first.callsign2+" "+contacts1.first.date.to_date.to_s end
       end
     end
     
     wwff_logs.push({park: park, count: contact_count, contacts: contacts.sort_by{|c| c.date}})
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
         parks.push(docpark: p.code, potapark: pp.first.code, name: pp.first.name)
       end
   end
   contacts2.each do |contact|
       pp=Asset.find_by(code: contact.asset1_codes)
       p=pp.linked_assets_by_type("park")
       if p and p.count>0 then 
         parks.push(docpark: p.first.code, potapark: pp.code, name: pp.name)
       end
   end
   parks=parks.uniq 

   parks.each do |park| 
     contacts1=Contact.where(" callsign1 = ? and (? = ANY(asset1_codes) or ? = ANY(asset1_codes))", self.callsign, park[:docpark], park[:potapark])
 
     dates=[]
     contacts1.each do |contact|
       dates.push(contact.date.to_date)
     end
     dates=dates.uniq
      
     dates.each do |date| 
       contacts1=Contact.where(" callsign1 = ? and (? = ANY(asset1_codes) or ? = ANY(asset1_codes)) and date >= ? and date < ? ", self.callsign, park[:docpark], park[:potapark], date.beginning_of_day,date.end_of_day)
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
