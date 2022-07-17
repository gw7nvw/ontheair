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

def valid_callsign? 
  valid_callsign=/d?[a-zA-Z]{1,2}\d{1,4}[a-zA-Z]{1,4}/
  if valid_callsign.match(self.callsign) then true else false end
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

 def has_award(award, threshold)
   if threshold==nil then
     uas=AwardUserLink.find_by_sql [ " select * from award_user_links where user_id = "+self.id.to_s+" and award_id = "+award.id.to_s+" and threshold is null" ]
   else
     uas=AwardUserLink.find_by_sql [ " select * from award_user_links where user_id = "+self.id.to_s+" and award_id = "+award.id.to_s+" and threshold = "+threshold.threshold.to_s ]
   end
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

 def bagged_qrp
   ats=AssetType.where(keep_score: true)
   at_list=ats.map{|at| "'"+at.name+"'"}.join(",")
   codes1=Contact.find_by_sql [" select distinct(asset1_codes) as asset1_codes from (select unnest(asset1_classes) as asset1_classes, unnest(asset1_codes) as asset1_codes from contacts where (callsign2='"+self.callsign+"' and is_qrp2=true) or (callsign1='"+self.callsign+"' and is_qrp1=true)) as c inner join assets a on a.code = c.asset1_codes where asset1_classes in ("+at_list+") and a.is_active=true and a.minor is not true; " ]
   codes2=Contact.find_by_sql [" select distinct(asset2_codes) as asset1_codes from (select unnest(asset2_classes) as asset2_classes, unnest(asset2_codes) as asset2_codes from contacts where (callsign2='"+self.callsign+"' and is_qrp2=true) or (callsign1='"+self.callsign+"' and is_qrp1=true)) as c inner join assets a on a.code = c.asset2_codes where asset2_classes in ("+at_list+") and a.is_active=true and a.minor is not true; " ]
   codes=[codes1.map{|c| c.asset1_codes}.join(","), codes2.map{|c| c.asset1_codes}.join(",") ].join(",").split(',').uniq
 end

 def bagged(asset_type = 'all')
   if asset_type=='all' then
     ats=AssetType.where(keep_score: true)
     at_list=ats.map{|at| "'"+at.name+"'"}.join(",")
     codes1=Contact.find_by_sql [" select distinct(asset1_codes) as asset1_codes from (select unnest(asset1_classes) as asset1_classes, unnest(asset1_codes) as asset1_codes from contacts where (callsign1='"+self.callsign+"' or callsign2='"+self.callsign+"')) as c inner join assets a on a.code = c.asset1_codes where a.is_active=true and a.minor is not true and asset1_classes in ("+at_list+"); " ]
     codes2=Contact.find_by_sql [" select distinct(asset2_codes) as asset1_codes from (select unnest(asset2_classes) as asset2_classes, unnest(asset2_codes) as asset2_codes from contacts where (callsign1='"+self.callsign+"' or callsign2='"+self.callsign+"')) as c inner join assets a on a.code = c.asset2_codes where a.is_active=true and a.minor is not true and asset2_classes in ("+at_list+"); " ]
   else
     codes1=Contact.find_by_sql [" select distinct(asset1_codes) as asset1_codes from (select unnest(asset1_classes) as asset1_classes, unnest(asset1_codes) as asset1_codes from contacts where (callsign1='"+self.callsign+"' or callsign2='"+self.callsign+"') and '"+asset_type+"'=ANY(asset1_classes)) as c inner join assets a on a.code = c.asset1_codes where asset1_classes='"+asset_type+"' and a.is_active=true and a.minor is not true; " ]
     codes2=Contact.find_by_sql [" select distinct(asset2_codes) as asset1_codes from (select unnest(asset2_classes) as asset2_classes, unnest(asset2_codes) as asset2_codes from contacts where (callsign1='"+self.callsign+"' or callsign2='"+self.callsign+"') and '"+asset_type+"'=ANY(asset2_classes)) as c inner join assets a on a.code = c.asset2_codes where asset2_classes='"+asset_type+"' and a.is_active=true and a.minor is not true; " ]
   end
   codes=[codes1.map{|c| c.asset1_codes}.join(","), codes2.map{|c| c.asset1_codes}.join(",") ].join(",").split(',').uniq
  end

  def activated_qrp
    ats=AssetType.where(keep_score: true)
    at_list=ats.map{|at| "'"+at.name+"'"}.join(",")
    codes1=Contact.find_by_sql [" select distinct(asset1_codes) as asset1_codes from (select unnest(asset1_classes) as asset1_classes, unnest(asset1_codes) as asset1_codes from contacts where callsign1='"+self.callsign+"' and is_qrp1=true) as c inner join assets a on a.code = c.asset1_codes where asset1_classes in ("+at_list+") and a.is_active=true and a.minor is not true; " ]
    codes2=Contact.find_by_sql [" select distinct(asset2_codes) as asset1_codes from (select unnest(asset2_classes) as asset2_classes, unnest(asset2_codes) as asset2_codes from contacts where callsign2='"+self.callsign+"' and is_qrp2=true) as c inner join assets a on a.code = c.asset2_codes where asset2_classes in ("+at_list+") and a.is_active=true and a.minor is not true; " ]
    codes=[codes1.map{|c| c.asset1_codes}.join(","), codes2.map{|c| c.asset1_codes}.join(",")].join(",").split(',').uniq
  end

  def activated(asset_type = 'all')
    if asset_type=='all' then
        ats=AssetType.where(keep_score: true)
        at_list=ats.map{|at| "'"+at.name+"'"}.join(",")
        codes1=Contact.find_by_sql [" select distinct(asset1_codes) as asset1_codes from (select unnest(asset1_classes) as asset1_classes, unnest(asset1_codes) as asset1_codes from contacts where callsign1='"+self.callsign+"') as c inner join assets a on a.code = c.asset1_codes where a.is_active=true and a.minor is not true and asset1_classes in ("+at_list+") ; " ]
        codes2=Contact.find_by_sql [" select distinct(asset2_codes) as asset1_codes from (select unnest(asset2_classes) as asset2_classes, unnest(asset2_codes) as asset2_codes from contacts where callsign2='"+self.callsign+"') as c inner join assets a on a.code = c.asset2_codes where a.is_active=true and a.minor is not true and asset2_classes in ("+at_list+") ; " ]
    else
        codes1=Contact.find_by_sql [" select distinct(asset1_codes) as asset1_codes from (select unnest(asset1_classes) as asset1_classes, unnest(asset1_codes) as asset1_codes from contacts where callsign1='"+self.callsign+"' and '"+asset_type+"'=ANY(asset1_classes)) as c inner join assets a on a.code = c.asset1_codes where asset1_classes='"+asset_type+"' and a.is_active=true and a.minor is not true; " ]
        codes2=Contact.find_by_sql [" select distinct(asset2_codes) as asset1_codes from (select unnest(asset2_classes) as asset2_classes, unnest(asset2_codes) as asset2_codes from contacts where callsign2='"+self.callsign+"' and '"+asset_type+"'=ANY(asset2_classes)) as c inner join assets a on a.code = c.asset2_codes where asset2_classes='"+asset_type+"' and a.is_active=true and a.minor is not true; " ]
    end
    codes=[codes1.map{|c| c.asset1_codes}.join(","), codes2.map{|c| c.asset1_codes}.join(",")].join(",").split(',').uniq
  end

  def chased_qrp
    ats=AssetType.where(keep_score: true)
    at_list=ats.map{|at| "'"+at.name+"'"}.join(",")
    codes1=Contact.find_by_sql [" select distinct(asset1_codes) as asset1_codes from (select unnest(asset1_classes) as asset1_classes, unnest(asset1_codes) as asset1_codes from contacts where callsign2='"+self.callsign+"' and is_qrp2=true) as c inner join assets a on a.code = c.asset1_codes where asset1_classes in ("+at_list+") and a.is_active=true and a.minor is not true; " ]
    codes2=Contact.find_by_sql [" select distinct(asset2_codes) as asset1_codes from (select unnest(asset2_classes) as asset2_classes, unnest(asset2_codes) as asset2_codes from contacts where callsign1='"+self.callsign+"' and is_qrp1=true) as c inner join assets a on a.code = c.asset2_codes where asset2_classes in ("+at_list+") and a.is_active=true and a.minor is not true; " ]
    codes=[codes1.map{|c| c.asset1_codes}.join(","), codes2.map{|c| c.asset1_codes}.join(",") ].join(",").split(',').uniq
  end

  def chased(asset_type = 'all')
    if asset_type=='all' then
      ats=AssetType.where(keep_score: true)
      at_list=ats.map{|at| "'"+at.name+"'"}.join(",")
      codes1=Contact.find_by_sql [" select distinct(asset1_codes) as asset1_codes from (select unnest(asset1_classes) as asset1_classes, unnest(asset1_codes) as asset1_codes from contacts where callsign2='"+self.callsign+"') as c inner join assets a on a.code = c.asset1_codes where a.is_active=true and a.minor is not true and asset1_classes in ("+at_list+"); " ]
      codes2=Contact.find_by_sql [" select distinct(asset2_codes) as asset1_codes from (select unnest(asset2_classes) as asset2_classes, unnest(asset2_codes) as asset2_codes from contacts where callsign1='"+self.callsign+"') as c inner join assets a on a.code = c.asset2_codes where a.is_active=true and a.minor is not true and asset2_classes in ("+at_list+"); " ]
    else
      codes1=Contact.find_by_sql [" select distinct(asset1_codes) as asset1_codes from (select unnest(asset1_classes) as asset1_classes, unnest(asset1_codes) as asset1_codes from contacts where callsign2='"+self.callsign+"' and '"+asset_type+"'=ANY(asset1_classes)) as c inner join assets a on a.code = c.asset1_codes where asset1_classes='"+asset_type+"' and a.is_active=true and a.minor is not true; " ]
      codes2=Contact.find_by_sql [" select distinct(asset2_codes) as asset1_codes from (select unnest(asset2_classes) as asset2_classes, unnest(asset2_codes) as asset2_codes from contacts where callsign1='"+self.callsign+"' and '"+asset_type+"'=ANY(asset2_classes)) as c inner join assets a on a.code = c.asset2_codes where asset2_classes='"+asset_type+"' and a.is_active=true and a.minor is not true; " ]
    end
    codes=[codes1.map{|c| c.asset1_codes}.join(","), codes2.map{|c| c.asset1_codes}.join(",") ].join(",").split(',').uniq
  end

  def chased_by_day(asset_type = 'all')
    if asset_type=='all' then
      ats=AssetType.where(keep_score: true)
      at_list=ats.map{|at| "'"+at.name+"'"}.join(",")

      codes1=Contact.find_by_sql [" select distinct(asset1_codes || ' ' || time::date) as asset1_codes from (select time, unnest(asset1_classes) as asset1_classes, unnest(asset1_codes) as asset1_codes from contacts where callsign2='"+self.callsign+"' and asset1_classes in ("+at_list+")) as c inner join assets a on a.code = c.asset1_codes where asset1_classes in ("+at_list+") and a.is_active=true and a.minor is not true; " ]
      codes2=Contact.find_by_sql [" select distinct(asset1_codes || ' ' || time::date) as asset1_codes from (select time, unnest(asset2_classes) as asset2_classes, unnest(asset2_codes) as asset2_codes from contacts where callsign1='"+self.callsign+"' and asset1_classes in ("+at_list+")) as c inner join assets a on a.code = c.asset2_codes where asset2_classes in ("+at_list+") and a.is_active=true and a.minor is not true; " ]
    else
      codes1=Contact.find_by_sql [" select distinct(asset1_codes || ' ' || time::date) as asset1_codes from (select time, unnest(asset1_classes) as asset1_classes, unnest(asset1_codes) as asset1_codes from contacts where callsign2='"+self.callsign+"' and '"+asset_type+"'=ANY(asset1_classes)) as c inner join assets a on a.code = c.asset1_codes where asset1_classes='"+asset_type+"' and a.is_active=true and a.minor is not true; " ]
      codes2=Contact.find_by_sql [" select distinct(asset2_codes || ' ' || time::date) as asset1_codes from (select time, unnest(asset2_classes) as asset2_classes, unnest(asset2_codes) as asset2_codes from contacts where callsign1='"+self.callsign+"' and '"+asset_type+"'=ANY(asset2_classes)) as c inner join assets a on a.code = c.asset2_codes where asset2_classes='"+asset_type+"' and a.is_active=true and a.minor is not true; " ]
    end
    codes=[codes1.map{|c| c.asset1_codes}.join(","), codes2.map{|c| c.asset1_codes}.join(",") ].join(",").split(',').uniq
  end

  def chased_qrp_by_day
    ats=AssetType.where(keep_score: true)
    at_list=ats.map{|at| "'"+at.name+"'"}.join(",")
    codes1=Contact.find_by_sql [" select distinct(asset1_codes || ' ' || time::date) as asset1_codes from (select time, unnest(asset1_classes) as asset1_classes, unnest(asset1_codes) as asset1_codes from contacts where callsign2='"+self.callsign+"' and is_qrp2=true) as c inner join assets a on a.code = c.asset1_codes  where asset1_classes in ("+at_list+") and a.is_active=true and a.minor is not true; " ]
    codes2=Contact.find_by_sql [" select distinct(asset2_codes || ' ' || time::date) as asset1_codes from (select time, unnest(asset2_classes) as asset2_classes, unnest(asset2_codes) as asset2_codes from contacts where callsign1='"+self.callsign+"' and is_qrp1=true) as c inner join assets a on a.code = c.asset2_codes  where asset2_classes in ("+at_list+") and a.is_active=true and a.minor is not true; " ]
    codes=[codes1.map{|c| c.asset1_codes}.join(","), codes2.map{|c| c.asset1_codes}.join(",") ].join(",").split(',').uniq
  end

  def activated_by_day(asset_type = 'all')
    if asset_type=='all' then
      ats=AssetType.where(keep_score: true)
      at_list=ats.map{|at| "'"+at.name+"'"}.join(",")
      codes1=Contact.find_by_sql [" select distinct(asset1_codes || ' ' || time::date) as asset1_codes from (select time, unnest(asset1_classes) as asset1_classes, unnest(asset1_codes) as asset1_codes from contacts where callsign1='"+self.callsign+"') as c inner join assets a on a.code = c.asset1_codes where asset1_classes in ("+at_list+") and a.is_active=true and a.minor is not true; " ]
      codes2=Contact.find_by_sql [" select distinct(asset1_codes || ' ' || time::date) as asset1_codes from (select time, unnest(asset2_classes) as asset2_classes, unnest(asset2_codes) as asset2_codes from contacts where callsign2='"+self.callsign+"') as c inner join assets a on a.code = c.asset2_codes where asset2_classes in ("+at_list+") and a.is_active=true and a.minor is not true; " ]
    else
      codes1=Contact.find_by_sql [" select distinct(asset1_codes || ' ' || time::date) as asset1_codes from (select time, unnest(asset1_classes) as asset1_classes, unnest(asset1_codes) as asset1_codes from contacts where callsign1='"+self.callsign+"' and '"+asset_type+"'=ANY(asset1_classes)) as c inner join assets a on a.code = c.asset1_codes where asset1_classes='"+asset_type+"' and a.is_active=true and a.minor is not true; " ]
      codes2=Contact.find_by_sql [" select distinct(asset2_codes || ' ' || time::date) as asset1_codes from (select time, unnest(asset2_classes) as asset2_classes, unnest(asset2_codes) as asset2_codes from contacts where callsign2='"+self.callsign+"' and '"+asset_type+"'=ANY(asset2_classes)) as c inner join assets a on a.code = c.asset2_codes where asset2_classes='"+asset_type+"' and a.is_active=true and a.minor is not true; " ]
    end
    codes=[codes1.map{|c| c.asset1_codes}.join(","), codes2.map{|c| c.asset1_codes}.join(",") ].join(",").split(',').uniq
  end

  def activated_by_year(asset_type = 'all')
    if asset_type=='all' then
      ats=AssetType.where(keep_score: true)
      at_list=ats.map{|at| "'"+at.name+"'"}.join(",")

      codes1=Contact.find_by_sql [" select distinct(asset1_codes || ' ' || date_part('year', time)) as asset1_codes from (select time, unnest(asset1_classes) as asset1_classes, unnest(asset1_codes) as asset1_codes from contacts where callsign1='"+self.callsign+"') as c inner join assets a on a.code = c.asset1_codes where asset1_classes in ("+at_list+") and a.is_active=true and a.minor is not true; " ]
      codes2=Contact.find_by_sql [" select distinct(asset1_codes || ' ' || date_part('year', time)) as asset1_codes from (select time, unnest(asset2_classes) as asset2_classes, unnest(asset2_codes) as asset2_codes from contacts where callsign2='"+self.callsign+"') as c inner join assets a on a.code = c.asset2_codes where asset2_classes in ("+at_list+") and a.is_active=true and a.minor is not true; " ]
    else
      codes1=Contact.find_by_sql [" select distinct(asset1_codes || ' ' || date_part('year', time)) as asset1_codes from (select time, unnest(asset1_classes) as asset1_classes, unnest(asset1_codes) as asset1_codes from contacts where callsign1='"+self.callsign+"' and '"+asset_type+"'=ANY(asset1_classes)) as c inner join assets a on a.code = c.asset1_codes where asset1_classes='"+asset_type+"' and a.is_active=true and a.minor is not true; " ]
      codes2=Contact.find_by_sql [" select distinct(asset2_codes || ' ' || date_part('year', time)) as asset1_codes from (select time, unnest(asset2_classes) as asset2_classes, unnest(asset2_codes) as asset2_codes from contacts where callsign2='"+self.callsign+"' and '"+asset_type+"'=ANY(asset2_classes)) as c inner join assets a on a.code = c.asset2_codes where asset2_classes='"+asset_type+"' and a.is_active=true and a.minor is not true; " ]
    end
    codes=[codes1.map{|c| c.asset1_codes}.join(","), codes2.map{|c| c.asset1_codes}.join(",") ].join(",").split(',').uniq

  end

  def activated_qrp_by_year
    ats=AssetType.where(keep_score: true)
    at_list=ats.map{|at| "'"+at.name+"'"}.join(",")
    codes1=Contact.find_by_sql [" select distinct(asset1_codes || ' ' || date_part('year', time)) as asset1_codes from (select time, unnest(asset1_classes) as asset1_classes, unnest(asset1_codes) as asset1_codes from contacts where callsign1='"+self.callsign+"' and is_qrp1=true) as c inner join assets a on a.code = c.asset1_codes where asset1_classes in ("+at_list+") and a.is_active=true and a.minor is not true; " ]
    codes2=Contact.find_by_sql [" select distinct(asset2_codes || ' ' || date_part('year', time)) as asset1_codes from (select time, unnest(asset2_classes) as asset2_classes, unnest(asset2_codes) as asset2_codes from contacts where callsign2='"+self.callsign+"' and is_qrp2=true) as c inner join assets a on a.code = c.asset2_codes where asset2_classes in ("+at_list+") and a.is_active=true and a.minor is not true; " ]
    codes=[codes1.map{|c| c.asset1_codes}.join(","), codes2.map{|c| c.asset1_codes}.join(",")].join(",").split(',').uniq
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

  def self.users_with_assets(sortby = "park", scoreby = "score", max_rows = 2000)
    callsigns=[]
    contacts1=Contact.find_by_sql [" select distinct callsign1 from contacts where asset1_classes is not null or asset2_classes is not null "]
    contacts2=Contact.find_by_sql [" select distinct callsign2 as callsign1 from contacts where asset1_classes is not null or asset2_classes is not null "]
    callsigns=((contacts1+contacts2).map{|c| c.callsign1}).uniq

    users=User.find_by_sql [ "select * from users where callsign in ("+callsigns.uniq.map{|c| "'"+c+"'"}.join(",")+") order by cast(substring(SUBSTRING("+scoreby+" from '"+sortby+": [0-9]{1,9}') from '[0-9]{1,9}') as integer) desc limit "+max_rows.to_s ]
  end

  def self.update_scores
    users=User.all
    users.each do |user|
       user.update_score
    end
  end

  def update_score
    ats=AssetType.where(keep_score: true)
    ats.each do |asset_type|
       self.score[asset_type.name]=self.bagged(asset_type.name).count
       self.score_total[asset_type.name]=0
       self.activated_count[asset_type.name]=self.activated(asset_type.name).count
       self.activated_count_total[asset_type.name]=self.activated_by_year(asset_type.name).count
       self.chased_count[asset_type.name]=self.chased(asset_type.name).count
       self.chased_count_total[asset_type.name]=self.chased_by_day(asset_type.name).count
    end
    qrp=AssetType.new
    qrp.name="qrp"
    ats << qrp

    self.score["qrp"]=self.bagged_qrp.count
    self.score_total["qrp"]=0
    self.activated_count["qrp"]=self.activated_qrp.count
    self.activated_count_total["qrp"]=self.activated_qrp_by_year.count
    self.chased_count["qrp"]=self.chased_qrp.count
    self.chased_count_total["qrp"]=self.chased_qrp_by_day.count

    self.score["p2p"]=self.get_p2p_all.count
    success=self.save
  end

  def get_p2p_all
    #all activations I make that are ZLOTA to /P
    ats=AssetType.where(keep_score: true)
    at_list=ats.map{|at| "'"+at.name+"'"}.join(",")

    p2p=[]

    contacts1=Contact.find_by_sql [ "select (split_part(asset1_code,' ', 1) || ' ' || split_part(asset2_code, ' ', 1) || ' ' || time::date) as asset1_code from (select c1.time as time, c1.date as date, c1.id as id, c1.callsign1 as callsign1, c1.callsign2 as callsign2, unnest(c1.asset1_codes) as asset1_code, unnest(c1.asset1_classes) as asset1_class, asset2_code from contacts c1 join (select id, unnest(asset2_codes) as asset2_code from contacts) c2 on c2.id=c1.id where c1.callsign1='"+self.callsign+"') as foo where asset1_class in ("+at_list+"); " ]
    contacts2=Contact.find_by_sql [ "select (split_part(asset1_code, ' ', 1) || ' ' || split_part(asset2_code, ' ', 1) || ' ' || time::date) as asset1_code from (select c1.time as time, c1.date as date, c1.id as id, c1.callsign1 as callsign1, c1.callsign2 as callsign2, unnest(c1.asset2_codes) as asset1_code, unnest(c1.asset2_classes) as asset1_class, asset2_code from contacts c1 join (select id, unnest(asset1_codes) as asset2_code from contacts) c2 on c2.id=c1.id where c1.callsign2='"+self.callsign+"') as foo where asset1_class in ("+at_list+"); " ]
    contacts=((contacts1+contacts2).map{|c| c.asset1_code}).uniq
  end


  def assets_by_type(asset_type, count_type)
    if asset_type=="qrp" then
      case count_type
      when 'activated'
        codes=self.activated_qrp
      when 'chased'
        codes=self.chased_qrp
      else
        codes=self.bagged_qrp
      end
    else
      case count_type
      when 'activated'
        codes=self.activated(asset_type)
      when 'chased'
        codes=self.chased(asset_type)
      else
        codes=self.bagged(asset_type)
      end
    end   
  end

  def contacts_by_type(asset_type, count_type)
    if asset_type=="qrp" then
      if count_type=="bagged" then
        query1="(callsign1 = '"+self.callsign+"' and is_qrp1=true) or (callsign2 = '"+self.callsign+"' and is_qrp2=true)" 
      else #activated, chased
        query1="callsign1 = '"+self.callsign+"' and is_qrp1=true"
        query2="callsign2 = '"+self.callsign+"' and is_qrp2=true"
      end
    else
      if count_type=="activated" then
        query1="callsign1 = '"+self.callsign+"' and '"+asset_type+"'=ANY(asset1_classes)"
        query2="callsign2 = '"+self.callsign+"' and '"+asset_type+"'=ANY(asset2_classes)"
      elsif count_type=="chased" then
        query1="callsign1 = '"+self.callsign+"' and '"+asset_type+"'=ANY(asset2_classes)"
        query2="callsign2 = '"+self.callsign+"' and '"+asset_type+"'=ANY(asset1_classes)"
      else  #bagged
        query1="(callsign1 = '"+self.callsign+"' or callsign2 = '"+self.callsign+"') and ('"+asset_type+"'=ANY(asset1_classes) or '"+asset_type+"'=ANY(asset2_classes))"
      end
    end
    if count_type=="bagged" then
      contacts=Contact.find_by_sql [ " select callsign1, callsign2, date, asset1_classes, asset1_codes, asset2_classes, asset2_codes from contacts where "+query1 ]
    else
      contacts1=Contact.find_by_sql [ " select callsign1, callsign2, date, asset1_classes, asset1_codes, asset2_classes, asset2_codes from contacts where "+query1 ]
      contacts2=Contact.find_by_sql [ " select callsign1 as callsign2, callsign2 as callsign1, date, asset1_classes as asset2_classes, asset1_codes as asset2_codes, asset2_classes as asset1_classes, asset2_codes as asset1_codes from contacts where "+query2 ]
      contacts=contacts1+contacts2
    end
  end



  def wwff_logs(resubmit)
   if resubmit==true then resubmit_str="" else resubmit_str=" and submitted_to_wwff is not true" end
   wwff_logs=[]
   puts "resubmit: "+resubmit_str
   contacts2=Contact.find_by_sql [ "select asset1_codes  from (select distinct unnest(asset1_codes) as asset1_codes  from contacts where callsign1 = '"+self.callsign+"'"+resubmit_str+" and 'wwff park'=ANY(asset1_classes)) as sq where asset1_codes  like 'ZLFF-%%'" ]

   parks=[]
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
#Now all contacts have all assets saved againstt them - this code looked for
#related assets and is no longer needed
#     dps=pp.linked_assets_by_type("park");
#     dpcodes=dps.map{|dp| dp.code}
#     contacts1=Contact.where(" callsign1 = ? and (? = ANY(asset1_codes) or (array[?]::varchar[] && asset1_codes))"+resubmit_str, self.callsign, park[:wwffpark], dpcodes)
     contacts1=Contact.where(" callsign1 = ? and (? = ANY(asset1_codes))"+resubmit_str, self.callsign, park[:wwffpark])

     contact_count=contacts1.count
     callsigns=[]
     contacts=[]
     contacts1.each do |contact| callsigns.push({callsign: contact.callsign2,date: contact.date.to_date}) end
     callsigns=callsigns.uniq
     contacts_count=callsigns.count

     callsigns.each do |cs|


       contacts1=Contact.where('callsign1= ? and callsign2 = ? and date >= ? and date < ? and (? = ANY(asset1_codes))'+resubmit_str,  self.callsign,  cs[:callsign], cs[:date].beginning_of_day,cs[:date].end_of_day, park[:wwffpark])
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
   logs=Log.find_by_sql [ "select * from logs where callsign1='#{self.callsign}'" ]

   summits=[]
   logs.each do |log|
     assets=log.activator_asset_links
     assets.each do |a|
       if a and a.asset_type=="summit" then
         summits.push(a)
       end
     end
   end
   summits=summits.uniq

   summits.each do |summit| 
     contactDates=Contact.find_by_sql [ "select distinct(date::date) from contacts where callsign1 = '#{self.callsign}' and '#{summit.code}' =ANY(asset1_codes)" ]
     dates=contactDates.map { |contact| contact.date }
       
     dates.each do |date| 
       contacts_submitted=Contact.find_by_sql [ "select count(id) as id from contacts where callsign1 = ? and ? = ANY(asset1_codes) and date >= ? and date < ? and submitted_to_sota=true", self.callsign,  summit.code, date.beginning_of_day,date.end_of_day ]
       contacts_unsubmitted=Contact.find_by_sql [ "select count(id) as id from contacts where callsign1 = ? and ? = ANY(asset1_codes) and date >= ? and date < ? and submitted_to_sota is not true", self.callsign,  summit.code, date.beginning_of_day,date.end_of_day ]
       contact_count=contacts_submitted.first.id+contacts_unsubmitted.first.id
       if contacts_unsubmitted.first.id>0 then submitted=false else submitted=true end 
       sota_logs.push({summit: summit, date: date, count: contact_count, submitted: submitted})  
     end
   end 
  sota_logs
  end

  def sota_chaser_contacts(summitCode = nil, resubmit = false)
   sota_logs=[]
   if resubmit==false then
     whereclause=" and submitted_to_sota is not true"
   else
     whereclause=""
   end
 
   if summitCode then
     contacts1=Contact.find_by_sql [ "select * from contacts where callsign1='#{self.callsign}' and '#{summitCode}' = ANY(asset2_codes))#{whereclause}; " ]
   else
     contacts1=Contact.find_by_sql [ "select * from contacts where callsign1='#{self.callsign}' and array_length(asset2_codes,1)>0#{whereclause};"]
   end

   chaser_contacts=[]
   contacts1.each do |contact|
     #do not include S2S
     activated=false
     contact.asset1_codes.each do |code|
       if code.match(/^[a-zA-Z]{1,2}\d{0,1}\/[a-zA-Z]{2}-\d{3}/) then
         activated=true
       end
     end
     if activated==false then
       contact.asset2_codes.each do |code|
         if code.match(/^[a-zA-Z]{1,2}\d{0,1}\/[a-zA-Z]{2}-\d{3}/) then
           chaser_contacts.push(contact)
           chaser_contacts.last.asset2_codes=[code]
         end
       end
     end
   end

   sota_logs[0]={summit: nil, date: nil, count: chaser_contacts.count, contacts: chaser_contacts.sort_by{|c| c.date} } 

   sota_logs
  end

  def sota_contacts(summitCode = nil)
   sota_logs=[]
   if summitCode then
     contacts1=Contact.find_by_sql [ "select * from contacts where callsign1='#{self.callsign}' and '#{summitCode}' = ANY(asset1_codes); " ]
   else 
     contacts1=Contact.find_by_sql [ "select * from contacts where callsign1='#{self.callsign} and array_length(asset1_codes,1)>0';"]
   end

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

   contacts2=Contact.find_by_sql [ "select asset1_codes  from (select distinct unnest(asset1_codes) as asset1_codes  from contacts where callsign1 = '"+self.callsign+"' and 'pota park'=ANY(asset1_classes)) as sq where asset1_codes  like 'ZL-%%'" ]

   parks=[]
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
#     dps=pp.linked_assets_by_type("park");
#     dpcodes=dps.map{|dp| dp.code}
#     puts dpcodes;
#     contacts1=Contact.where(" callsign1 = ? and (? = ANY(asset1_codes) or (array[?]::varchar[] && asset1_codes))", self.callsign, park[:potapark], dpcodes)
     contacts1=Contact.where(" callsign1 = ? and (? = ANY(asset1_codes))", self.callsign, park[:potapark])
 
     dates=[]
     contacts1.each do |contact|
       dates.push(contact.date.to_date)
     end
     dates=dates.uniq
      
     dates.each do |date| 
       contacts1=Contact.where(" callsign1 = ? and (? = ANY(asset1_codes)) and date >= ? and date < ? ", self.callsign, park[:potapark], date.beginning_of_day,date.end_of_day)
       contact_count=contacts1.count
       contacts=[]
       contacts1.each do |contact| contacts.push(contact) end
       pota_logs.push({park: park, date: date, count: contact_count, contacts: contacts.sort_by{|c| c.date}})  
     end
   end 
  pota_logs
  end

def awards
   awls=AwardUserLink.where(user_id: self.id)
end

def check_awards()
  user=self
  awarded=[]
  awards=Award.where(:is_active => true)
  awards.each do |award|
    if !(user.has_award(award,nil)) then
      failcount=0
      if award.count_based==true then
         if award.activated==true and award.chased == true then
           #we need a complete count! 
         elsif award.activated==true then
           score=user.activated_count[award.programme]
         elsif award.chased==true then
           score=user.chased_count[award.programme]
         else
           score=user.score[award.programme]
         end
         puts(award.name, score)
         if score then
           AwardThreshold.all.each do |threshold|
             if score >= threshold.threshold
               if !(user.has_award(award,threshold)) then
                 a=AwardUserLink.new
                 a.award_id=award.id
                 a.threshold=threshold.threshold
                 a.user_id=user.id
                 a.save
               end
             end
           end
        end
      end
    end
  end
end

  private

    def create_remember_token
      self.remember_token = User.digest(User.new_token)
    end

    def downcase_email
      self.email = email.downcase
    end


end
