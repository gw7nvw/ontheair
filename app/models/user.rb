class User < ActiveRecord::Base
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

  def huts
    huts=self.huts_filtered(false, false)
  end

  def hut_count_filtered(user_qrp, contact_qrp, revisits)
   huts=[]
   contacts=self.contacts_filtered(user_qrp, contact_qrp)
   contacts.each do |c|
       if c.hut1 then 
         if revisits then huts.push(c.hut1.id.to_s+" "+c.localdate(nil).to_s)
         else huts.push(c.hut1.id.to_s) end
       end
       if c.hut2 then 
         if revisits then huts.push(c.hut2.id.to_s+" "+c.localdate(nil).to_s)
         else huts.push(c.hut2.id.to_s) end
       end
   end
   huts.uniq.count
  end

  def huts_filtered(user_qrp, contact_qrp)
   huts=[]
   contacts=self.contacts_filtered(user_qrp, contact_qrp)
   contacts.each do |c|
       if c.hut1 then huts.push(c.hut1.id) end
       if c.hut2 then huts.push(c.hut2.id) end
   end

   huts=Hut.where(id: huts).order(:name)
  end

  def parks
    parks=self.parks_filtered(false, false)
  end

  def park_count_filtered(user_qrp, contact_qrp, revisits)
   huts=[]
   contacts=self.contacts_filtered(user_qrp, contact_qrp)
   contacts.each do |c|
       if c.park1 then
         if revisits then huts.push(c.park1.id.to_s+" "+c.localdate(nil).to_s)
         else huts.push(c.park1.id.to_s) end
       end
       if c.park2 then
         if revisits then huts.push(c.park2.id.to_s+" "+c.localdate(nil).to_s)
         else huts.push(c.park2.id.to_s) end
       end
   end
   huts.uniq.count
  end


  def parks_filtered(user_qrp, contact_qrp)
   parks=[]
   contacts=self.contacts
   contacts.each do |c|
     if c.park1 then parks.push(c.park1.id) end
     if c.park2 then parks.push(c.park2.id) end
   end

   parks=Park.where(id: parks).order(:name)
  end
  
  def islands
    islands=self.islands_filtered(false, false)
  end
 
  def islands_filtered(user_qrp, contact_qrp)
   islands=[]
   contacts=self.contacts
   contacts.each do |c|
     if c.island1 then islands.push(c.island1.id) end
     if c.island2 then islands.push(c.island2.id) end
   end

   islands=Island.where(id: islands).order(:name)
  end

  def island_count_filtered(user_qrp, contact_qrp, revisits)
   huts=[]
   contacts=self.contacts_filtered(user_qrp, contact_qrp)
   contacts.each do |c|
       if c.island1 then
         if revisits then huts.push(c.island1.id.to_s+" "+c.localdate(nil).to_s)
         else huts.push(c.island1.id.to_s) end
       end
       if c.island2 then
         if revisits then huts.push(c.island2.id.to_s+" "+c.localdate(nil).to_s)
         else huts.push(c.island2.id.to_s) end
       end
   end
   huts.uniq.count
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

  def pota_logs
   pota_logs=[]
   contacts1=Contact.where(callsign1: callsign)
   contacts2=Contact.where(callsign2: callsign)

   parks=[]
   contacts1.each do |contact|
     if contact.park1 and contact.park1.pota_park then
       parks.push(contact.park1)
     end
   end
   contacts2.each do |contact|
     if contact.park2 and contact.park2.pota_park then
       parks.push(contact.park2)
     end
   end
   parks=parks.uniq

   parks.each do |park| 
     contacts1=Contact.where(callsign1: self.callsign, park1_id: park.id)
     contacts2=Contact.where(callsign2: self.callsign, park2_id: park.id)
     dates=[]
     contacts1.each do |contact|
       dates.push(contact.date.to_date)
     end
     contacts2.each do |contact|
       dates.push(contact.date.to_date)
     end
     dates=dates.uniq
      
     dates.each do |date| 
       contacts1=Contact.where(callsign1: self.callsign, park1_id: park.id, date: date.beginning_of_day..date.end_of_day)
       contacts2=Contact.where(callsign2: self.callsign, park2_id: park.id, date: date.beginning_of_day..date.end_of_day)
       contact_count=contacts1.count+contacts2.count
       contacts=[]
       contacts1.each do |contact| contacts.push(contact) end
       contacts2.each do |contact| contacts.push(contact) end
       pota_logs.push({park: park, date: date, count: contact_count, contacts: contacts})  
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
