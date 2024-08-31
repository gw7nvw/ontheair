 class User < ActiveRecord::Base
  serialize :score, Hash
  serialize :score_total, Hash
  serialize :activated_count, Hash
  serialize :activated_count_total, Hash
  serialize :qualified_count, Hash
  serialize :qualified_count_total, Hash
  serialize :chased_count, Hash
  serialize :chased_count_total, Hash

  attr_accessor :remeber_token, :activation_token, :reset_token

  before_validation { if self.email then self.email = email.downcase end }
  before_validation { self.callsign = (callsign||"").strip.upcase }
  
  before_save { if self.timezone==nil then self.timezone=Timezone.find_by(name: 'UTC').id end }
  before_save { if self.pin==nil or self.pin.length<4 then self.pin=self.callsign.chars.shuffle[0..3].join end; self.pin=self.pin[0..3] }
  after_save :add_callsigns
  before_create :create_remember_token

  VALID_NAME_REGEX = /\A[a-zA-Z\d\s]*\z/i
  validates :callsign,  presence: true, length: { maximum: 50 },
                uniqueness: { case_sensitive: false }, format: { with: VALID_NAME_REGEX }

  VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i
  has_secure_password

  VALID_PHONE_REGEX = /\A\+[1-9]\d{1,14}\z/i
  validates :acctnumber, allow_blank: true, format: { with: VALID_PHONE_REGEX }

  def User.new_token
    SecureRandom.urlsafe_base64
  end

  def User.digest(token)
    Digest::SHA1.hexdigest(token.to_s)
  end

#############################################################################################
# Return all callsigns for current user 
#############################################################################################
def callsigns
  UserCallsign.where(user_id: self.id)
end

#############################################################################################
# Is current callsign valid
###############################################################################################
def valid_callsign? 
  valid_callsign=/^\d{0,1}[a-zA-Z]{1,2}\d{1,4}[a-zA-Z]{1,4}$/
  if valid_callsign.match(self.callsign) then true else false end
end

#############################################################################################
# Returns true if a password reset has expired.
#############################################################################################
def password_reset_expired?
  reset_sent_at < 2.hours.ago
end

#############################################################################################
# Authenticate password reset token against current account 
# Returns:
#   True: Digest
#   False: Nil
#############################################################################################
def authenticated?(attribute, token)
  digest = send("#{attribute}_digest")
  return false if digest.nil?
  Digest::SHA1.hexdigest(token.to_s)==digest
end

#############################################################################################
# Activate the current account. 
#############################################################################################
def activate
  update_attribute(:activated,    true)
  update_attribute(:activated_at, Time.zone.now)
end


#############################################################################################
# Send account actiuivation email 
#############################################################################################
def send_activation_email
  UserMailer.account_activation(self).deliver
end


#############################################################################################
# Return a password reset digest for current user
#############################################################################################
def create_reset_digest
  self.reset_token = User.new_token
  update_attribute(:reset_digest,  User.digest(reset_token))
  update_attribute(:reset_sent_at, Time.zone.now)
end

#############################################################################################
# Send password reset email for current user
#############################################################################################
def send_password_reset_email
  UserMailer.password_reset(self).deliver
end

#############################################################################################
# Sends youve been signed up choose a password email.
#############################################################################################
def send_new_password_email
  UserMailer.new_password(self).deliver
end


#############################################################################################
# Returns a valid account activation digest for current user
#############################################################################################
def create_activation_digest
  self.activation_token = User.new_token
  self.activation_digest = User.digest(activation_token)
end


#############################################################################################
# Find user using a callsign with prefixes
#############################################################################################
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


#############################################################################################
# CALCULATED FIELDS
#############################################################################################

##############################################################################################
# Return name of current user's timezone or "" if not set
# Returns:
#    (string) timezone.name
#############################################################################################
def timezonename
  timezonename=""
  if self.timezone!="" then
    tz=Timezone.find_by_id(self.timezone)
    if tz then timezonename=tz.name end
  end
  timezonename
end

#############################################################################################
# Return all contacts for this user including those entered by others 
# Returns:
#    [Contact]
#############################################################################################
def contacts
  contacts=Contact.find_by_sql [ "select * from contacts where user1_id="+self.id.to_s+" or user2_id="+self.id.to_s+" order by date, time"]
end

#############################################################################################
# Return all logs created by this user
# Returns:
#    [Log]
#############################################################################################
def logs
  logs=Log.find_by_sql [ "select * from logs where user1_id="+self.id.to_s+" order by date"]
end


#############################################################################################
# return links to all current user's awards 
# Returns:
#  [UserAwardLink]
#############################################################################################
def awards
  awls=AwardUserLink.where(user_id: self.id)
end



###########################################################################################
# SCORE CALCULATION
###########################################################################################

###########################################################################################
# List bagged (uniques) assets for this user
# Input:
#  - params:
#       [:asset_type] - Asset.type to report or 'all' (default)
#       [:include_minor] - Also include 'minor' assets not valid for ZLOTA
#       [:qrp] - Only QRP conatcts
# Returns:
#       codes: Array of asset codes
##########################################################################################
def bagged(params={})
  asset_type='all'
  qrp=false
  include_minor=false
  if params[:asset_type] then asset_type=params[:asset_type] end
  if params[:include_minor] then include_minor=params[:include_minor] end
  if params[:qrp] then qrp=params[:qrp] end

  if include_minor==false then minor_query='a.minor is not true' else minor_query='true' end
  if qrp==true then
    qrp_query1="is_qrp1 is true"
    qrp_query2="is_qrp2 is true"
  else
    qrp_query1="true"
    qrp_query2="true"
  end
  if asset_type=='all' then
    ats=AssetType.where(keep_score: true)
    at_list=ats.map{|at| "'"+at.name+"'"}.join(",")
  else
    at_list=asset_type.split(',').map{|at| "'"+at.strip+"'"}.join(",")
  end

  codes1=Contact.find_by_sql [" select distinct(asset1_codes) as asset1_codes from (select unnest(asset1_classes) as asset1_classes, unnest(asset1_codes) as asset1_codes from contacts where ((user1_id="+self.id.to_s+" and "+qrp_query1+") or (user2_id="+self.id.to_s+" and "+qrp_query2+"))) as c inner join assets a on a.code = c.asset1_codes where a.is_active=true and #{minor_query} and a.asset_type in ("+at_list+"); " ]
  codes2=Contact.find_by_sql [" select distinct(asset2_codes) as asset1_codes from (select unnest(asset2_classes) as asset2_classes, unnest(asset2_codes) as asset2_codes from contacts where ((user1_id="+self.id.to_s+" and "+qrp_query1+") or (user2_id="+self.id.to_s+" and "+qrp_query2+"))) as c inner join assets a on a.code = c.asset2_codes where a.is_active=true and #{minor_query} and a.asset_type in ("+at_list+"); " ]
  codes=[codes1.map{|c| c.asset1_codes}.join(","), codes2.map{|c| c.asset1_codes}.join(",") ].join(",").split(',').uniq
  codes=codes.select{ |c| c.length>0 }
end

###########################################################################################
# List chased assets for this user [optionally by day / year]
# Input:
#  - params:
#       [:asset_type] - Asset.type to report or 'all' (default)
#       [:include_minor] - Also include 'minor' assets not valid for ZLOTA
#       [:include_external] - Also include contacts from external databases (e.g. SOTA, POTA)
#       [:qrp] - Only QRP conatcts
#       [:by_day] - Show unique (asset, date) combinations 
#       [:by_year] - Show unique (asset, year) combinations
#       ...... i.e. list repeats if they happen on different years / days
#       ...... default is list unique chases once for all time
# Returns:
#       codes: Array of ["(asset code)"] or ["(asset_code) (year)"] or ["(asset_code) (date)"]
##########################################################################################
def chased(params={})
  asset_type='all'
  include_minor=false
  include_external=false
  qrp=false
  qrp_query1="true"
  qrp_query2="true"
  date_query=""
  date_query_ext=""
  codes3=[]

  if params[:asset_type] then asset_type=params[:asset_type] end
  if params[:include_minor] then include_minor=params[:include_minor] end
  if params[:include_external] then include_external=params[:include_external] end
  if params[:qrp] then qrp=params[:qrp] end
  if params[:by_day] then
    date_query=" || ' ' || time::date"
    date_query_ext=",' ', date::date"
  end
  if params[:by_year] then
    date_query=" || ' ' || date_part('year', time)"
    date_query_ext=",' ', extract('year' from date)"
  end

  if include_minor==false then minor_query='a.minor is not true' else minor_query='true' end

  if qrp==true then
    qrp_query1="is_qrp2=true"
    qrp_query2="is_qrp1=true"
  end


  if asset_type=='all' then
    ats=AssetType.where(keep_score: true)
    at_list=ats.map{|at| "'"+at.name+"'"}.join(",")
  else
    at_list=asset_type.split(',').map{|at| "'"+at.strip+"'"}.join(",")
  end


  codes1=Contact.find_by_sql [" select distinct(asset1_codes"+date_query+") as asset1_codes from (select time, unnest(asset1_classes) as asset1_classes, unnest(asset1_codes) as asset1_codes from contacts where user2_id="+self.id.to_s+" and "+qrp_query1+") as c inner join assets a on a.code = c.asset1_codes where a.asset_type in ("+at_list+") and a.is_active=true and #{minor_query}; " ]
  codes2=Contact.find_by_sql [" select distinct(asset2_codes"+date_query+") as asset1_codes from (select time, unnest(asset2_classes) as asset2_classes, unnest(asset2_codes) as asset2_codes from contacts where user1_id="+self.id.to_s+" and "+qrp_query2+") as c inner join assets a on a.code = c.asset2_codes where a.asset_type in ("+at_list+") and a.is_active=true and #{minor_query}; " ]
  if include_external==true
    codes3=SotaChase.find_by_sql [ " select concat(summit_code"+date_query_ext+") as summit_code from sota_chases where user_id='#{self.id}';"]
  end
  codes=[codes1.map{|c| c.asset1_codes}.join(","), codes2.map{|c| c.asset1_codes}.join(","), codes3.map{|c| c.summit_code}.join(",")].join(",").split(',').uniq
  codes=codes.select{ |c| c.length>0 }
end

###########################################################################################
# List activated assets for this user [optionally by day / year]
# Input:
#  - params:
#       [:asset_type] - Asset.type to report or 'all' (default)
#       [:include_minor] - Also include 'minor' assets not valid for ZLOTA
#       [:include_external] - Also include contacts from external databases (e.g. SOTA, POTA)
#       [:qrp] - Only QRP conatcts
#       [:by_day] - Show unique (asset, date) combinations 
#       [:by_year] - Show unique (asset, year) combinations
#       ...... i.e. list repeats if they happen on different years / days
#       ...... default is list unique activations once for all time
# Returns:
#       codes: Array of ["(asset code)"] or ["(asset_code) (year)"] or ["(asset_code) (date)"]
##########################################################################################
def activations(params={})
  asset_type='all'
  include_minor=false
  include_external=false
  qrp=false
  qrp_query1="true"
  qrp_query2="true"
  date_query=""
  date_query_ext=""
  codes3=[]

  if params[:asset_type] then asset_type=params[:asset_type] end
  if params[:include_minor] then include_minor=params[:include_minor] end
  if params[:include_external] then include_external=params[:include_external] end
  if params[:qrp] then qrp=params[:qrp] end
  if params[:by_day] then 
    date_query=" || ' ' || time::date" 
    date_query_ext=",' ', date::date"
  end
  if params[:by_year] then 
    date_query=" || ' ' || date_part('year', time)" 
    date_query_ext=",' ', extract('year' from date)"
  end

  if include_minor==false then minor_query='a.minor is not true' else minor_query='true' end

  if qrp==true then
    qrp_query1="is_qrp1=true"
    qrp_query2="is_qrp2=true"
  end


  if asset_type=='all' then
    ats=AssetType.where(keep_score: true)
    at_list=ats.map{|at| "'"+at.name+"'"}.join(",")
  else
    at_list=asset_type.split(',').map{|at| "'"+at.strip+"'"}.join(",")
  end

  codes1=Contact.find_by_sql [" select distinct(asset1_codes"+date_query+") as asset1_codes from (select time, unnest(asset1_classes) as asset1_classes, unnest(asset1_codes) as asset1_codes from contacts where user1_id="+self.id.to_s+" and "+qrp_query1+") as c inner join assets a on a.code = c.asset1_codes where a.asset_type in ("+at_list+") and a.is_active=true and #{minor_query}; " ]
  codes2=Contact.find_by_sql [" select distinct(asset2_codes"+date_query+") as asset1_codes from (select time, unnest(asset2_classes) as asset2_classes, unnest(asset2_codes) as asset2_codes from contacts where user2_id="+self.id.to_s+" and "+qrp_query2+") as c inner join assets a on a.code = c.asset2_codes where a.asset_type in ("+at_list+") and a.is_active=true and #{minor_query}; " ]
  if include_external==true
    codes3=SotaActivation.find_by_sql [ " select concat(summit_code"+date_query_ext+") as summit_code from sota_activations where user_id='#{self.id}';"]
  end
  codes=[codes1.map{|c| c.asset1_codes}.join(","), codes2.map{|c| c.asset1_codes}.join(","), codes3.map{|c| c.summit_code}.join(",")].join(",").split(',').uniq
  codes=codes.select{ |c| c.length>0 }
end


###########################################################################################
# List qualified assets for this user
# Input:
#  - params:
#       [:asset_type] - Asset.type to report ('all' is not supported for qualified)
#       [:include_external] - include contacts from external databases (e.g. SOTA, POTA)
#       [:include_minor] - include minor assets
#       [:by_day] - List location multiple times if qualified on different days
#       [:by_year] - List location multiple times if qualified on different years
#       Note: QRP filter is not supported
# Returns:
#       codes: Array of ["(asset code)"]
# TODO: this method is very slow.  Improve it
##########################################################################################
def qualified(params={})
  if !params[:asset_type] then 
    raise "asset_type is required in User.qualified"
  end
  codes=self.activations(asset_type: params[:asset_type], include_external: params[:include_external], include_minor: params[:include_minor])

  codes=self.filter_by_min_qso(codes,params)

  codes=codes
end

# Filter list of ["asset_code"] (or ["asset_code date"]) by min QSO requirements for 
# activations of that asset by this user
def filter_by_min_qso(codes,params={})
  asset_type='all'
  use_external=false
  date_group="'forever'"

  if params[:asset_type] then asset_type=params[:asset_type] end
  if params[:by_year] then 
     date_group="extract('year' from date)"
  end
  if params[:by_day] then 
     date_group="date::date"
  end

  at=AssetType.find_by(name: asset_type)
  result_codes=[]
  qual_codes2=[]
  if params[:include_external] then
    qual_codes2=SotaActivation.find_by_sql [ " 
        select concat(summit_code, ' ', "+date_group+") as summit_code 
        from sota_activations 
        where user_id='#{self.id}' and qso_count>=#{at.min_qso} and summit_code in (?)
       ;", codes ]
  end
  if at and at.min_qso and at.min_qso>0 then
      qual_codes=Asset.find_by_sql [ " 
           select code, 
             unnest(array(
               select concat(a.code, ' ', period) as periodcode from (
                 select "+date_group+" as period, count(qso_count) as act_count from (
                   select * from (
                     select date, count(*) as qso_count from (
                       select distinct callsign1, callsign2, date::date as date from (
                           select id, callsign1, callsign2, date from contacts c where (c.user1_id='#{self.id}' and a.code=ANY(c.asset1_codes)) 
                         union 
                           select id, callsign2 as callsign1, callsign1 as callsign2, date  from contacts c where  (c.user2_id='#{self.id}' and a.code=ANY(c.asset2_codes))
                       ) as uniquecontacts 
                     ) as uniqueactivatons group by date 
                   ) as actcount where qso_count>=#{at.min_qso} 
                 ) as periodcount group by period
               ) as validcount where act_count>0 group by periodcode
             )) as periodcode from assets a
             where a.code in (?)
          ;", codes ]
  end
  result_codes=qual_codes.map{|qc| qc.periodcode}
  result_codes+=qual_codes2.map{|qc| qc.summit_code}
  result_codes=result_codes.uniq.map{|rc| rc.split(' ')[0]}
end


###########################################################################################
# Update score fields for this user
#
# Returns:
#   success: boolean
###########################################################################################
def update_score
  ats=AssetType.where('keep_score is not false')
  ats.each do |asset_type|
    if asset_type.name=='summit' then
      include_external=true
    else
      include_external=false
    end
    self.score[asset_type.name]=self.bagged(asset_type: asset_type.name).count
    self.score_total[asset_type.name]=0
    self.activated_count[asset_type.name]=self.activations(asset_type: asset_type.name, include_external: include_external).count
    self.activated_count_total[asset_type.name]=self.activations(by_year: true, asset_type: asset_type.name, include_external: include_external).count
    self.qualified_count[asset_type.name]=self.qualified(asset_type: asset_type.name,include_external: include_external).count
    self.qualified_count_total[asset_type.name]=self.qualified(by_year: true, asset_type: asset_type.name, include_external: include_external).count
    self.chased_count[asset_type.name]=self.chased(asset_type: asset_type.name).count
    self.chased_count_total[asset_type.name]=self.chased(asset_type: asset_type.name, by_day: true).count
  end
    
  qrp=AssetType.new
  qrp.name="qrp"
  ats << qrp

  self.score["qrp"]=self.bagged(qrp: true).count
  self.score_total["qrp"]=0
  self.activated_count["qrp"]=self.activations(qrp: true).count
  self.activated_count_total["qrp"]=self.activations(qrp: true, by_year: true).count
  self.chased_count["qrp"]=self.chased(qrp: true).count
  self.chased_count_total["qrp"]=self.chased(qrp: true, by_day: true).count

  self.score['elevation']=self.elevation_bagged(include_external: true)
  self.qualified_count_total['elevation']=self.elevation_qualified(include_external: true, by_day: true)
  self.activated_count_total['elevation']=self.elevation_activated(include_external: true, by_day: true)
  self.chased_count_total['elevation']=self.elevation_chased(include_external: true, by_day: true)

  self.score["p2p"]=self.get_p2p_all.count

  success=self.save
end

###########################################################################################
# ELEVATION STATS
###########################################################################################

###########################################################################################
# Sum elevation of all bagged assets
# Input:
#  - params are the same as bagged except:
#       [:asset_type] - not supported
#       QRP filter is not supported
# Returns:
#       elevation: cumulative elevation in meters
##########################################################################################
def elevation_bagged(params={})
  elevation=0
  ats=AssetType.where(has_elevation: true)
  params[:asset_type]=ats.map{|at| at.name}.join(",")

  codes=self.bagged(params)
  codes.each do |code|
    asset=Asset.find_by(code: code)
    if asset and asset.altitude!=nil then elevation+=asset.altitude end
  end
  elevation
end

###########################################################################################
# Sum elevation of all chased assets
# Input:
#  - params are the same as chased except:
#       [:asset_type] - not supported
#       QRP filter is not supported
# Returns:
#       elevation: cumulative elevation in meters
##########################################################################################
def elevation_chased(params={})
  elevation=0
  ats=AssetType.where(has_elevation: true)
  params[:asset_type]=ats.map{|at| at.name}.join(",")

  codes=self.chased(params)
  codes.each do |code|
    asset=Asset.find_by(code: code.split(' ')[0])
    if asset and asset.altitude!=nil then elevation+=asset.altitude end
  end
  elevation
end

###########################################################################################
# Sum elevation of all qualified assets
# Input:
#  - params are the same as qualified except:
#       [:asset_type] - not supported
# Returns:
#       elevation: cumulative elevation in meters
##########################################################################################
def elevation_qualified(params={})
  elevation=0
  ats=AssetType.where(has_elevation: true)
  codes=[]
  ats.each do |at|
    params[:asset_type]=at.name
    codes+=self.qualified(params)
  end
  codes.each do |code|
    asset=Asset.find_by(code: code.split(' ')[0])
    if asset and asset.altitude!=nil then elevation+=asset.altitude end
  end
  elevation
end

###########################################################################################
# Sum elevation of all activated assets
# Input:
#  - params are the same as activated except:
#       [:asset_type] - not supported
#       QRP filter is not supported
# Returns:
#       elevation: cumulative elevation in meters
##########################################################################################
def elevation_activated(params={})
  elevation=0
  ats=AssetType.where(has_elevation: true)
  params[:asset_type]=ats.map{|at| at.name}.join(",")
  
  codes=self.activations(params)
  codes.each do |code|
    asset=Asset.find_by(code: code.split(' ')[0])
    if asset and asset.altitude!=nil then elevation+=asset.altitude end
  end
  elevation
end

###########################################################################################
# Return a list of users who have bagged / activated / chased anything, 
# ordered by count of baggings /  activations / chases of specified asset type, decreasing
# Limit search to max_rows (default: 2000)
#
# Returns:
#       users: [User]
###########################################################################################
def self.users_with_assets(sortby = "park", scoreby = "score", max_rows = 2000)
  users=User.find_by_sql [" 
    select * from users 
      where cast(substring(SUBSTRING("+scoreby+" from '"+sortby+": [0-9]{1,9}') from ' [0-9]{1,9}') as integer)>0
      and "+scoreby+" not like '%%{}%%' 
    order by cast(substring(SUBSTRING("+scoreby+" from '"+sortby+": [0-9]{1,9}') from ' [0-9]{1,9}') as integer) desc 
    limit "+max_rows.to_s 
  ]
end

###########################################################################################
# List all unique P2P contacts for current user
# Returns:
#   p2p: [contact_details] - Array of unique values of "<date> <asset1_code> <asset2_code>" 
#                          from all contacts for this user where one or other asset_code
#                          is in ZLOTA
###########################################################################################
def get_p2p_all
  #list of all ZLOTA asset types
  ats=AssetType.where(keep_score: true)
  at_list=ats.map{|at| "'"+at.name+"'"}.join(",")

  p2p=[]
  #contacts where I'm in ZLOTA
  contacts1=Contact.find_by_sql [ "select (time::date || ' ' || split_part(asset1_code,' ', 1) || ' ' || split_part(asset2_code, ' ', 1)) as asset1_code from (select c1.time as time, c1.date as date, c1.id as id, c1.user1_id as user1_id, c1.user2_id as user2_id, unnest(c1.asset1_codes) as asset1_code, unnest(c1.asset1_classes) as asset1_class, asset2_code from contacts c1 join (select id, unnest(asset2_codes) as asset2_code from contacts) c2 on c2.id=c1.id where c1.user1_id="+self.id.to_s+") as foo where asset1_class in ("+at_list+"); " ]
  contacts2=Contact.find_by_sql [ "select (time::date || ' ' || split_part(asset1_code, ' ', 1) || ' ' || split_part(asset2_code, ' ', 1)) as asset1_code from (select c1.time as time, c1.date as date, c1.id as id, c1.user1_id as user1_id, c1.user2_id as user2_id, unnest(c1.asset2_codes) as asset1_code, unnest(c1.asset2_classes) as asset1_class, asset2_code from contacts c1 join (select id, unnest(asset1_codes) as asset2_code from contacts) c2 on c2.id=c1.id where c1.user2_id="+self.id.to_s+") as foo where asset1_class in ("+at_list+"); " ]
  #contacts where other party  ZLOTA (reverse code order so my loc first
  #to avoid double-counting ZLOTA-ZLOTA
  contacts3=Contact.find_by_sql [ "select (time::date || ' ' || split_part(asset2_code,' ', 1) || ' ' || split_part(asset1_code, ' ', 1)) as asset1_code from (select c1.time as time, c1.date as date, c1.id as id, c1.user1_id as user1_id, c1.user2_id as user2_id, unnest(c1.asset1_codes) as asset1_code, unnest(c1.asset1_classes) as asset1_class, asset2_code from contacts c1 join (select id, unnest(asset2_codes) as asset2_code from contacts) c2 on c2.id=c1.id where c1.user2_id="+self.id.to_s+") as foo where asset1_class in ("+at_list+"); " ]
  contacts4=Contact.find_by_sql [ "select (time::date || ' ' || split_part(asset2_code, ' ', 1) || ' ' || split_part(asset1_code, ' ', 1)) as asset1_code from (select c1.time as time, c1.date as date, c1.id as id, c1.user1_id as user1_id, c1.user2_id as user2_id, unnest(c1.asset2_codes) as asset1_code, unnest(c1.asset2_classes) as asset1_class, asset2_code from contacts c1 join (select id, unnest(asset1_codes) as asset2_code from contacts) c2 on c2.id=c1.id where c1.user1_id="+self.id.to_s+") as foo where asset1_class in ("+at_list+"); " ]
  contacts=((contacts1+contacts2+contacts3+contacts4).map{|c| c.asset1_code}).uniq
end


##################################################################################
# WRAPPERS
##################################################################################

##################################################################################
# Single function to call activated / bagged / chased based on parameters passed
# Input:
#   asset_type: AssetType.name or 'qrp'
#   count_type: 'activated' or 'chased' or 'bagged'
#   include_minor: true / false - include minor assets in list
# Returns:
#   codes: array of [Asset.code] 
##################################################################################
def assets_by_type(asset_type, count_type, include_minor=false)
  if asset_type=="qrp" then
    case count_type
    when 'activated'
      codes=self.activations(qrp: true, include_minor: include_minor)
    when 'chased'
      codes=self.chased(qrp: true, include_minor: include_minor)
    else
      codes=self.bagged(qrp: true, include_minor: include_minor)
    end
  else
    case count_type
    when 'activated'
      codes=self.activations(asset_type: asset_type, include_minor: include_minor)
    when 'chased'
      codes=self.chased(asset_type: asset_type, include_minor: include_minor)
    else
      codes=self.bagged(asset_type: asset_type, include_minor: include_minor)
    end
  end   
  codes
end


#################################################################################
# LOGS 
#################################################################################

#################################################################################
# Return array of WWFF logs for current user
# Input:
#   resubmit: false: include only contacts not previously submitted in logs
#             true: include all contacts in logs
# Returns:
#  wwff_logs: Array of logs per wwff_park:
#    [
#       park: Asset - wwff_park this logs pertains to
#       count: integer - count of valid contacts in this log
#       contacts: [Contact] - array of unique contacts from this park
#       dups: [Contact] - array of contacts dropped as duplicates
#    ]
###############################################################################
def wwff_logs(resubmit=false)
  if resubmit==true then resubmit_str="" else resubmit_str=" and submitted_to_wwff is not true" end
  wwff_logs=[]
  logger.debug "resubmit: "+resubmit_str

  contacts2=Contact.find_by_sql [ "select distinct asset1_codes  from (select distinct unnest(asset1_codes) as asset1_codes  from contacts where user1_id = "+self.id.to_s+""+resubmit_str+" and 'wwff park'=ANY(asset1_classes)) as sq where asset1_codes like 'ZLFF-%%'" ]
  references=contacts2.map{|c| c.asset1_codes}

  #get list of contacts for each park
  references.each do |park|
    pp=Asset.find_by(code: park);
    if pp then
      #all contacts for this user from this park
      contacts1=Contact.find_by_sql ["select distinct callsign2, date::date as date, band, mode from contacts where  user1_id = ? and (? = ANY(asset1_codes)) and (date >= ?)"+resubmit_str, self.id, park,pp.valid_from ]
      contacts=[]
      dups=[]

      # for each unique chaser / date / mode / band combination 
      # add 1st matching contacts to valid list
      # and add remainder to duplicates list
      contacts1.each do |c|
        contacts2=Contact.find_by_sql [" select * from contacts where user1_id= ? and callsign2 = ? and band = ? and mode = ? and date::date = ? and (? = ANY(asset1_codes))"+resubmit_str+" order by time asc;",  self.id,  c.callsign2, c.band, c.mode, c.date.strftime("%Y-%m-%d"), park]
        if contacts2 and contacts2.count>0 then
          contacts.push(contacts2.first)
          if contacts2.count>1 then dups=dups+contacts2[1..-1] end
        end
      end
     
      if contacts.count>0 then wwff_logs.push({park: {name: pp.name, wwffpark: pp.code}, count: contacts.uniq.count, contacts: contacts.uniq.sort_by{|c| c.date}, dups: dups.uniq}) end
    end
  end
  wwff_logs
end

#################################################################################
# Return array of SOTA logs for current user
# Returns:
#  sota_logs: Array of logs per summit per day:
#    [
#       code: Asset.code for the summit
#       name: Asset.name for the summit
#       date: date for the activation
#       safecode: Asset.safecode for the summit
#       count: integer - count of valid contacts in this log
#       submitted: integer - count of contacts in this log alrady submitted 
#    ]
###############################################################################
def sota_logs(summitCode=nil)
  if summitCode==nil then
    summitQuery1="'summit'=ANY(asset1_classes)"
    summitQuery2="c1.asset1_classes='summit'"
  else
    summitQuery1="'#{summitCode}'=ANY(asset1_codes)"
    summitQuery2="c1.asset1_codes='#{summitCode}'"
  end

  sota_logs=Contact.find_by_sql [ "
      select a.name, a.safecode, c3.* from
        (select asset1_codes as code, date, 
          count(case submitted_to_sota when true then 1 else null end) as submitted, 
          count(date) as count 
          from
            (select callsign1, callsign2, date::date as date, asset1_codes, submitted_to_sota from
               (select callsign1, callsign2, date, 
                  unnest(asset1_classes) as asset1_classes, 
                  unnest(asset1_codes) as asset1_codes,
                  submitted_to_sota
                  from contacts 
                  where user1_id=#{self.id} and #{summitQuery1}) as c1
               where #{summitQuery2}) as c2
          group by asset1_codes, date) as c3
        inner join assets a on a.code=c3.code;
    "]
  sota_logs
end

#################################################################################
# Return array containing single SOTA chaser log plus contacts for current user
# Returns:
#  sota_contacts: Array containing one log and multiple contacts
#    [
#       code: nil
#       date: nil
#       count: integer - count of valid contacts in this log
#       contacts: Array of [Contact]
#    ]
###############################################################################
def sota_chaser_contacts(summitCode = nil, resubmit = false)
  sota_logs=[]
  if resubmit==false then
    submitted_clause=" and submitted_to_sota is not true"
  else
    submitted_clause=""
  end

  if summitCode then 
    summit_clause="and '#{summitCode}' = ANY(c1.asset2_codes)"
  else
    summit_clause="and 'summit'=ANY(c1.asset2_classes)"
  end

  chaser_contacts=Contact.find_by_sql [ "
       select * from (
         select id, log_id, callsign1, callsign2, mode, frequency, band, is_portable1, 
           is_portable2, date, time, asset1_codes, asset1_classes,
           unnest(c1.asset2_classes) as asset2_classes,
           unnest(c1.asset2_codes) as asset2_codes 
           from contacts c1
           where c1.user1_id='#{self.id}' 
             and not ('summit'=ANY(c1.asset1_classes)) 
             #{summit_clause}
             #{submitted_clause}
       ) as c2
       where c2.asset2_classes='summit'
       order by c2.time asc; " ]

  sota_logs[0]={code: nil, date: nil, count: chaser_contacts.count, contacts: chaser_contacts} 

  sota_logs
end

#################################################################################
# Return array of sota_logs, including contacts for all or specified summit 
# for this user
# Returns:
#  sota_contacts: Array containing one log and multiple contacts
#    [
#       code: summitCode
#       date: activationDate
#       count: integer - count of valid contacts in this log
#       contacts: Array of [Contact]
#    ]
###############################################################################
def sota_contacts(summitCode = nil)
  sota_contacts=[]
  sota_logs=self.sota_logs(summitCode)
 
  sota_logs.each do |sota_log|
     contacts=Contact.where("user1_id = ? and ? = ANY(asset1_codes) and date::date= ?", self.id,  sota_log[:code], sota_log[:date].strftime("%Y-%m-%d")).order(:time)
     contact_count=contacts.count
     sota_contacts.push({code: sota_log[:code], date: sota_log[:date], count: contact_count, contacts: contacts})  
  end 
  sota_contacts
end

#################################################################################
# Return array of POTA logs for current user
# Returns:
#  pota_logs: Array of logs per park per day:
#    [
#       code: Asset.code for the park
#       name: Asset.name for the park
#       date: date for the activation
#       safecode: Asset.safecode for the park
#       count: integer - count of valid contacts in this log
#       submitted: integer - count of contacts in this log alrady submitted 
#    ]
###############################################################################
def pota_logs(parkCode=nil)
  if parkCode==nil then
    parkQuery1="'pota park'=ANY(asset1_classes)"
    parkQuery2="c1.asset1_classes='pota park'"
  else
    parkQuery1="'#{parkCode}'=ANY(asset1_codes)"
    parkQuery2="c1.asset1_codes='#{parkCode}'"
  end

  pota_logs=Contact.find_by_sql [ "
      select a.name, a.safecode, c3.* from
        (select asset1_codes as code, date, 
          count(case submitted_to_pota when true then 1 else null end) as submitted, 
          count(date) as count 
          from
            (select callsign1, callsign2, date::date as date, asset1_codes, submitted_to_pota from
               (select callsign1, callsign2, date, 
                  unnest(asset1_classes) as asset1_classes, 
                  unnest(asset1_codes) as asset1_codes,
                  submitted_to_pota
                  from contacts 
                  where user1_id=#{self.id} and #{parkQuery1}) as c1
               where #{parkQuery2}) as c2
            group by asset1_codes, date) as c3
        inner join assets a on a.code=c3.code;
    "]
  pota_logs
end

#################################################################################
# Return array of pota_logs, including contacts for all or specified park 
# for this user
# Returns:
#  pota_contacts: Array containing one log and multiple contacts
#    [
#       code: Asset.code for this park
#       date: date for the activation
#       count: integer - count of valid contacts in this log
#       contacts: Array of [Contact]
#    ]
###############################################################################
def pota_contacts(parkCode = nil)
  pota_contacts=[]
  pota_logs=self.pota_logs(parkCode)

  pota_logs.each do |pota_log|
     contacts=Contact.where("user1_id = ? and ? = ANY(asset1_codes) and date::date= ?", self.id,  pota_log[:code], pota_log[:date].strftime("%Y-%m-%d"))
     contact_count=contacts.count
     pota_contacts.push({code: pota_log[:code], date: pota_log[:date], count: contact_count, contacts: contacts.sort_by{|c| c.date}})
   end
  pota_contacts
end

##############################################################################
# AWARDS
#
# AREA-BASED (COMPLETION) AWARDS
##############################################################################


##############################################################################
# Find all activations for this user by region / district 
#
# Inputs:
#  - scope: 'district' or 'region'
#  - include_minor - include places marked as 'minor' (default=false)
# Returns:
#  - activations: [
#                   {
#                     type: AssetType.name
#                     name: Region.sota_code / District.code
#                     site_list: [string] - array of asset codes
#                   }
#                 ] array of ...
############################################################################
def area_activations(scope, include_minor=false)
  if include_minor==false then minor_query='a.minor is not true' else minor_query='true' end
  
  activations=Contact.find_by_sql [" 
    select array_agg(DISTINCT asset1_code) as site_list, 
      a.asset_type as type, a.#{scope} as name 
    from 
      (
        (
          select date, unnest(asset1_codes) as asset1_code 
          from contacts c 
          where user1_id="+self.id.to_s+"
        ) union (
          select date, unnest(asset2_codes) as asset1_code 
          from contacts 
          where user2_id="+self.id.to_s+"
        ) union (
          select date, summit_code as asset1_code 
          from sota_activations 
          where user_id="+self.id.to_s+"
        )
      ) as foo 
    inner join assets a on a.code=asset1_code 
    where #{minor_query} 
      and (a.valid_from is null or a.valid_from<=foo.date) 
      and ((a.valid_to is null and a.is_active=true) or a.valid_to>=foo.date) 
    group by a.#{scope}, a.asset_type, a.minor; 
  "]
end

##############################################################################
# Find all chases for this user by region / district 
#
# Inputs:
#  - scope: 'district' or 'region'
#  - include_minor - include places marked as 'minor' (default=false)
# Returns:
#  - chases: [
#               {
#                 type: AssetType.name
#                 name: Region.sota_code / District.code
#                 site_list: [string] - array of asset codes
#               }
#             ] array of ...
############################################################################
def area_chases(scope, include_minor=false)
  if include_minor==false then minor_query='a.minor is not true' else minor_query='true' end

  chases=Contact.find_by_sql [" 
    select array_agg(DISTINCT asset1_code) as site_list, 
      a.asset_type as type, a.#{scope} as name 
    from 
      (
        (
          select date, unnest(asset2_codes) as asset1_code 
          from contacts c 
          where user1_id="+self.id.to_s+"
        ) union (
          select date, unnest(asset1_codes) as asset1_code 
          from contacts 
          where user2_id="+self.id.to_s+"
        ) union (
          select date, summit_code as asset1_code 
          from sota_chases 
          where user_id="+self.id.to_s+"
        )
      ) as foo 
    inner join assets a on a.code=asset1_code 
    where #{minor_query} 
      and (a.valid_from is null or a.valid_from<=foo.date) 
      and ((a.valid_to is null and a.is_active=true) or a.valid_to>=foo.date) 
    group by a.#{scope}, a.asset_type, a.minor; 
  "]
end


#############################################################################################
# check if current user has a specific region/district completion award
# Input:
#   - scope: 'region' / 'district'
#   - loc_id: id for region/district being checked
#   - activity_type: AssetType.name for award 
#   - award_class: Award
# Returns:
#   True / False
#############################################################################################
def has_completion_award(scope, loc_id, activity_type, award_class)
  uas=AwardUserLink.find_by_sql [ " select * from award_user_links where user_id = "+self.id.to_s+" and award_type='"+scope+"' and linked_id="+loc_id.to_s+" and activity_type='"+activity_type+"' and award_class='"+award_class+"' and expired is not true "]
  if uas and uas.count>0 then true else false end
end

#############################################################################################
# Retire existing award for current user for specific region/district completion award
# E.g. after log deletion or additional assets added to that region
# Input:
#   - scale: 'region' / 'district'
#   - loc_id: id for region/district being checked
#   - activity_type: AssetType.name for award 
#   - award_class: Award
# Returns:
#############################################################################################
def retire_completion_award(scale, loc_id, activity_type, award_class)
  uas=AwardUserLink.find_by_sql [ " select * from award_user_links where user_id = "+self.id.to_s+" and award_type='"+scale+"' and linked_id="+loc_id.to_s+" and activity_type='"+activity_type+"' and award_class='"+award_class+"' and expired is not true "]
  uas.each do |ua|
    logger.warn "Retiring "+self.callsign+" "+loc_id.to_s+" "+scale+" "+activity_type+" "+award_class
    ua.expired=true
    ua.expired_at=Time.now()
    ua.save
  end
end

#############################################################################################
# Issue award for current user for specific region/district completion award
# if the user does not already have the award
# Input:
#   - scale: 'region' / 'district'
#   - loc_id: id for region/district being checked
#   - activity_type: AssetType.name for award 
#   - award_class: Award
# Returns:
#############################################################################################
def issue_completion_award(scope, loc_id, activity_type, award_class)
  award=nil
  if activity_type=='chaser' then
    chased=true; activated=false
  elsif activity_type=='activator' then
    chased=false; activated=true
  end
  award_spec=Award.find_by(chased: chased, activated: activated, programme: award_class, "all_"+scope => true, is_active: true)
  if award_spec and !(self.has_completion_award(scope, loc_id, activity_type, award_class)) then
    logger.debug "Awarded!! "+self.callsign+" "+award_class+" "+scope+" "+activity_type+" "+loc_id.to_s
    award=AwardUserLink.new
    award.award_type=scope
    award.linked_id=loc_id
    award.activity_type=activity_type
    award.award_class=award_class
    award.user_id=self.id
    award.award_id=award_spec.id
    award.save
    award.publicise
  end
  award
end

##############################################################################
# Check if user has earned region / district awards
#
# Inputs:
#  - scope: 'region' or 'district'
#
# Actions:
#  - Issues new award to user if new region / district activated
#  - Revokes old award if region / district previously activated no longer qualifies
#  - Issues new award to user if new region / district chased
#  - Revokes old award if region / district previously chased no longer qualifies
#############################################################################
def check_completion_awards(scope)
  if scope=='district' then
    modelname=District
    indexfield="district_code"
    award="all_district"
  elsif scope=='region' then
    modelname=Region
    indexfield="sota_code"
    award="all_region"
  else
    raise "Invalid scope for area award: "+scope.to_s
  end

  avail=modelname.get_assets_with_type
  activations=self.area_activations(scope)
  chases=self.area_chases(scope)
  avail.each do |combo|
     activation=activations.select {|a| a.name==combo.name and a.type==combo.type}
     chase=chases.select {|c| c.name==combo.name and c.type==combo.type}
     if activation and activation.count>0 then
       site_count=combo.site_list.count
       site_act=activation.first.site_list.count
       site_not_act=(combo.site_list-activation.first.site_list).count
       d=modelname.find_by(indexfield => combo.name)
       if site_not_act==0 then
         #issue award if not already issued
         self.issue_completion_award(scope, d.id, "activator", combo.type) 
       else
         #check for expired award
         self.retire_completion_award(scope, d.id, "activator", combo.type) 
       end
     end

     if chase and chase.count>0 then
       site_count=combo.site_list.count
       site_chased=chase.first.site_list.count
       site_not_chased=(combo.site_list-chase.first.site_list).count
       d=modelname.find_by(indexfield => combo.name)
       if site_not_chased==0 then
         #issue award if not already issued
         self.issue_completion_award(scope, d.id, "chaser", combo.type) 
       else
         #check for expired award
         self.retire_completion_award(scope, d.id, "chaser", combo.type) 
       end
     end
  end 
end


##############################################################################
# THRESHOLD-BASED AWARDS
##############################################################################
##############################################################################
# Show status of threshold-based award for this user
#
# Inputs:
#  - award_id: Award.id for the award being checked
#  - threshold: award threshold to be checked
# Returns:
#  - awarded: { 
#               status: <boolean> - award achieled (at thresold level if supplied)
#               latest:<integer> - latest threshold acheived
#               next: <integer> - next threshold available
#             }
#############################################################################
def has_award(award_id, threshold=nil)
    awarded={status: false, latest: nil, next: nil}
    score=0
    awls=AwardUserLink.find_by_sql [" select * from award_user_links where user_id="+self.id.to_s+" and award_id="+award_id.to_s+" order by threshold desc limit 1"]
    if awls and awls.count==1 then
      awarded[:latest]=awls.first.threshold_name.capitalize+" ("+awls.first.threshold.to_s+")"
      score=awls.first.threshold
      if score==threshold or threshold==nil then awarded[:status]=true end
    end
    if score then
      nextThreshold=AwardThreshold.find_by_sql [" select * from award_thresholds where threshold>"+score.to_s+" order by threshold asc limit 1" ]
      if nextThreshold and nextThreshold.count==1 then
        awarded[:next]=nextThreshold.first.name.capitalize+" ("+nextThreshold.first.threshold.to_s+")"
      end
    end
    awarded
end

##############################################################################
# Issue an award (if user does not already have it)
#
# Inputs:
# - award: Award
# - threshold: integer (threshold value for award)
#############################################################################
def issue_award(award_id, threshold)
  if !(self.has_award(award_id,threshold)[:status]) then
    a=AwardUserLink.new
    a.award_id=award_id
    a.threshold=threshold
    a.award_type="threshold"
    a.user_id=self.id
    a.save
    a.publicise
  end
end

##############################################################################
# Check is user has earned threshold-based awards
#
# Inputs:
#
# Actions:
#  - Issues new award to user if new threshold-based award acheived
#############################################################################
def check_awards()
  user=self
  awarded=[]
  awards=Award.where(:is_active => true)
  awards.each do |award|
    if !(user.has_award(award.id,nil)[:status]) then
      if award.count_based==true then
         if award.activated==true and award.chased == true then
           #this is where completed awards would go, when the code supports them!
         elsif award.activated==true then
           score=user.qualified_count_total[award.programme]
         elsif award.chased==true then
           score=user.chased_count_total[award.programme]
         else
           score=user.score[award.programme]
         end
         if score then
           AwardThreshold.all.each do |threshold|
             if score >= threshold.threshold
               user.issue_award(award,threshold.threshold)
             end
           end
        end
      end
    end
  end
end

###############################################################################
# CALLSIGN HANDLING
###############################################################################

###############################################################################
# Create userCallsign entries for current user, if missing
###############################################################################
def add_callsigns
  dup=UserCallsign.where(user_id: self.id, callsign: self.callsign)
  if !dup or dup.count==0 then
    uc=UserCallsign.new
    uc.user_id=self.id
    uc.from_date=Time.new(1900,1,1)
    uc.callsign=self.callsign
    uc.save 
    logger.debug "Added: "+self.callsign
  end
end

###############################################################################
# Find user by callsign valid on a given date
#
# Optionally, create the user if missing:
#   If callsign does not exist at all, create an auto-creted user for the callsign
#   If callsign does exist, but on another date, FAIL and return nil
#
# Parameters:
#  - callsign: string - callsign to search for
#  - date: Date - date to search on
#  - create: boolean (optional) - if true then user created for call if not found
# Returns:
#  - user: [User] or nil 
###############################################################################
# Find a user by one of their callsigns, valid on a given date
def self.find_by_callsign_date(callsign, c_date, create=false)
  uc=UserCallsign.find_by_sql [ " select * from user_callsigns where callsign=? and from_date<=? and (to_date is null or to_date>=?) ",callsign, c_date, c_date ]
  if uc and uc.count>0 then 
    uc.first.user 
  else 
    if create==true then
      user=User.create_dummy_user(callsign)  
    else
      nil
    end
  end
end

###############################################################################
# Check if a callsign exists. 
# If not, Create a 'dummy' user for that callsign, giving no login rights
# Returns:
# - user: [User] or nil if call already exists
###############################################################################
def self.create_dummy_user(callsign)
  dup=UserCallsign.find_by(callsign: callsign)
  if !dup then
    logger.debug "Create callsign: "+callsign
    user=User.create(callsign: callsign, activated: false, password: 'dummy', password_confirmation: 'dummy', timezone: 1)
  else
    nil
  end
end

###############################################################################
# Update logs / contacts for specific callsign to new user using that call on
# dates they own that callsign
# - called after new callsign added, or dates on callsign changed
###############################################################################
def self.reassign_userids_used_by_callsign(callsign)
  ls=Log.find_by_sql ["select * from logs where callsign1=?", callsign]
  ls.each do |l|
      l.save
  end

  #only callsign2 as callsign1 picked up by logs (above)
  cs=Contact.find_by_sql [" select * from contacts where callsign2=?", callsign]
  cs.each do |c|
      c.save
  end

  sas=SotaActivation.find_by_sql ["select * from sota_activations where callsign=?", callsign]
  sas.each do |sa|
     sa.save
  end
end

##########################################################################
# ADMIN TOOLS - COMMAND-LINE USE ONLY
##########################################################################

###############################################################################
# Update score for all users - called only from console
###############################################################################
def self.update_scores
  users=User.all
  users.each do |user|
     user.update_score
  end
end

###############################################################################
# Re-build callsigns table for all user's primary callsigns
###############################################################################
def self.add_all_callsigns
  us=User.all
  us.each do |user|
    user.add_callsigns
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
