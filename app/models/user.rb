# frozen_string_literal: true
# frozen_string_literal: true

# typed: false
class User < ActiveRecord::Base
  serialize :score, Hash
  serialize :score_total, Hash
  serialize :activated_count, Hash
  serialize :activated_count_total, Hash
  serialize :confirmed_activated_count, Hash
  serialize :confirmed_activated_count_total, Hash
  serialize :qualified_count, Hash
  serialize :qualified_count_total, Hash
  serialize :chased_count, Hash
  serialize :chased_count_total, Hash

  attr_accessor :remeber_token, :activation_token, :reset_token

  before_validation { self.email = email.downcase if email }
  before_validation { self.callsign = (callsign || '').strip.upcase }

  before_save { if timezone.nil? then self.timezone = Timezone.find_by(name: 'UTC').id end }
  before_save do
    self.pin = callsign.chars.sample(4).join if pin.nil? || (pin.length < 4)
    self.pin = pin[0..3]
  end
  after_save :add_callsigns
  before_create :create_remember_token

  VALID_NAME_REGEX = /\A[a-zA-Z\d\s]*\z/i
  validates :callsign, presence: true, length: { maximum: 50 },
                       uniqueness: { case_sensitive: false }, format: { with: VALID_NAME_REGEX }

  VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i
  has_secure_password

  VALID_PHONE_REGEX = /\A\+[1-9]\d{1,14}\z/i
  validates :acctnumber, allow_blank: true, format: { with: VALID_PHONE_REGEX }

  VALID_CALLSIGN_REGEX = /^\d{0,1}[a-zA-Z]{1,2}\d{1,4}[a-zA-Z]{1,4}$/

  def self.new_token
    SecureRandom.urlsafe_base64
  end

  def self.digest(token)
    Digest::SHA1.hexdigest(token.to_s)
  end

  #############################################################################################
  # Return all callsigns for current user
  #############################################################################################
  def callsigns
    UserCallsign.where(user_id: id)
  end

  #############################################################################################
  # Is current callsign valid
  ###############################################################################################
  def valid_callsign?
    VALID_CALLSIGN_REGEX.match(callsign) ? true : false
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
    Digest::SHA1.hexdigest(token.to_s) == digest
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
    user = if callsign && !callsign.empty?
             User.find_by(callsign: User.remove_call_suffix(callsign))
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
    timezonename = ''
    if timezone != ''
      tz = Timezone.find_by_id(timezone)
      timezonename = tz.name if tz
    end
    timezonename
  end

  #############################################################################################
  # Return all contacts for this user including those entered by others
  # Returns:
  #    [Contact]
  #############################################################################################
  def contacts
    Contact.find_by_sql ['select * from contacts where user1_id=' + id.to_s + ' or user2_id=' + id.to_s + ' order by date, time']
  end

  #############################################################################################
  # Return all chaser contacts which trigger this user to have an activation that they have
  # not logged themselves
  # Returns:
  #    [Contact]
  #############################################################################################
  def orphan_activations
    codes = activations(orphan_activations: true, by_year: true, asset_type: 'everything')
    contacts = []
    codes.each do |code_year|
      code = code_year.split(' ')[0]
      year = code_year.split(' ')[1]
      contacts += Contact.find_by_sql [" select * from contacts where user2_id=#{id} and '#{code}'=ANY(asset2_codes) and date_part('year', time)='#{year}';"]
    end
    contacts
  end

  #############################################################################################
  # Return all logs created by this user
  # Returns:
  #    [Log]
  #############################################################################################
  def logs
    Log.find_by_sql ['select * from logs where user1_id=' + id.to_s + ' order by date']
  end

  #############################################################################################
  # return links to all current user's awards
  # Returns:
  #  [UserAwardLink]
  #############################################################################################
  def awards
    AwardUserLink.where(user_id: id)
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
  def bagged(params = {})
    asset_type = 'all'
    qrp = false
    include_minor = false
    include_external = false
    codes3 = []
    codes4 = []

    asset_type = params[:asset_type] if params[:asset_type]
    include_minor = params[:include_minor] if params[:include_minor]
    qrp = params[:qrp] if params[:qrp]
    include_external = params[:include_external] if params[:include_external]

    minor_query = include_minor == false ? 'a.minor is not true' : 'true'
    if qrp == true
      qrp_query1 = 'is_qrp1 is true'
      qrp_query2 = 'is_qrp2 is true'
    else
      qrp_query1 = 'true'
      qrp_query2 = 'true'
    end
    if asset_type == 'all'
      ats = AssetType.where(keep_score: true)
      at_list = ats.map { |at| "'" + at.name + "'" }.join(',')
    elsif asset_type == 'everything'
      ats = AssetType.where("name != 'all'")
      at_list = ats.map { |at| "'" + at.name + "'" }.join(',')
    else
      at_list = asset_type.split(',').map { |at| "'" + at.strip + "'" }.join(',')
    end

    codes1 = Contact.find_by_sql [' select distinct(asset1_codes) as asset1_codes from (select unnest(asset1_classes) as asset1_classes, unnest(asset1_codes) as asset1_codes from contacts where ((user1_id=' + id.to_s + ' and ' + qrp_query1 + ') or (user2_id=' + id.to_s + ' and ' + qrp_query2 + "))) as c inner join assets a on a.code = c.asset1_codes where a.is_active=true and #{minor_query} and a.asset_type in (" + at_list + '); ']
    codes2 = Contact.find_by_sql [' select distinct(asset2_codes) as asset1_codes from (select unnest(asset2_classes) as asset2_classes, unnest(asset2_codes) as asset2_codes from contacts where ((user1_id=' + id.to_s + ' and ' + qrp_query1 + ') or (user2_id=' + id.to_s + ' and ' + qrp_query2 + "))) as c inner join assets a on a.code = c.asset2_codes where a.is_active=true and #{minor_query} and a.asset_type in (" + at_list + '); ']
    if include_external == true
      codes3 = ExternalChase.find_by_sql [" select concat(summit_code) as summit_code from external_chases where user_id='#{id}' and asset_type in (" + at_list + ');']
      codes4 = ExternalActivation.find_by_sql [" select concat(summit_code) as summit_code from external_activations where user_id='#{id}' and asset_type in (" + at_list + ');']
    end
    codes = [codes1.map(&:asset1_codes).join(','), codes2.map(&:asset1_codes).join(','), codes3.map(&:summit_code).join(','), codes4.map(&:summit_code).join(',')].join(',').split(',').uniq
    codes.reject(&:empty?)
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
  def chased(params = {})
    asset_type = 'all'
    include_minor = false
    include_external = false
    qrp = false
    qrp_query1 = 'true'
    qrp_query2 = 'true'
    date_query = ''
    date_query_ext = ''
    codes3 = []

    asset_type = params[:asset_type] if params[:asset_type]
    include_minor = params[:include_minor] if params[:include_minor]
    include_external = params[:include_external] if params[:include_external]
    qrp = params[:qrp] if params[:qrp]
    if params[:by_day]
      date_query = " || ' ' || time::date"
      date_query_ext = ",' ', date::date"
    end
    if params[:by_year]
      date_query = " || ' ' || date_part('year', time)"
      date_query_ext = ",' ', extract('year' from date)"
    end

    minor_query = include_minor == false ? 'a.minor is not true' : 'true'

    if qrp == true
      qrp_query1 = 'is_qrp2=true'
      qrp_query2 = 'is_qrp1=true'
    end

    if asset_type == 'all'
      ats = AssetType.where(keep_score: true)
      at_list = ats.map { |at| "'" + at.name + "'" }.join(',')
    elsif asset_type == 'everything'
      ats = AssetType.where("name != 'all'")
      at_list = ats.map { |at| "'" + at.name + "'" }.join(',')
    else
      at_list = asset_type.split(',').map { |at| "'" + at.strip + "'" }.join(',')
    end

    codes1 = Contact.find_by_sql [' select distinct(asset1_codes' + date_query + ') as asset1_codes from (select time, unnest(asset1_classes) as asset1_classes, unnest(asset1_codes) as asset1_codes from contacts where user2_id=' + id.to_s + ' and ' + qrp_query1 + ') as c inner join assets a on a.code = c.asset1_codes where a.asset_type in (' + at_list + ") and a.is_active=true and #{minor_query}; "]
    codes2 = Contact.find_by_sql [' select distinct(asset2_codes' + date_query + ') as asset1_codes from (select time, unnest(asset2_classes) as asset2_classes, unnest(asset2_codes) as asset2_codes from contacts where user1_id=' + id.to_s + ' and ' + qrp_query2 + ') as c inner join assets a on a.code = c.asset2_codes where a.asset_type in (' + at_list + ") and a.is_active=true and #{minor_query}; "]
    if include_external == true
      codes3 = ExternalChase.find_by_sql [' select concat(summit_code' + date_query_ext + ") as summit_code from external_chases where user_id='#{id}' and asset_type in (" + at_list + ');']
    end
    codes = [codes1.map(&:asset1_codes).join(','), codes2.map(&:asset1_codes).join(','), codes3.map(&:summit_code).join(',')].join(',').split(',').uniq
    codes.reject(&:empty?)
  end

  ###########################################################################################
  # List activated assets for this user [optionally by day / year]
  # Input:
  #  - params:
  #       [:asset_type] - Asset.type to report or 'all' (default)
  #       [:include_minor] - Also include 'minor' assets not valid for ZLOTA
  #       [:include_external] - Also include contacts from external databases (e.g. SOTA, POTA)
  #       [:only_activator] - Only check activator logs
  #       [:orphan_activations] - Check for activations in chaser logs but not activator
  #       [:qrp] - Only QRP conatcts
  #       [:by_day] - Show unique (asset, date) combinations
  #       [:by_year] - Show unique (asset, year) combinations
  #       ...... i.e. list repeats if they happen on different years / days
  #       ...... default is list unique activations once for all time
  # Returns:
  #       codes: Array of ["(asset code)"] or ["(asset_code) (year)"] or ["(asset_code) (date)"]
  ##########################################################################################
  def activations(params = {})
    result_type = 'all'
    asset_type = 'all'
    include_minor = false
    include_external = false
    qrp = false
    qrp_query1 = 'true'
    qrp_query2 = 'true'
    date_query = ''
    date_query_ext = ''
    codes3 = []

    asset_type = params[:asset_type] if params[:asset_type]
    result_type = 'only_activator' if params[:only_activator]
    result_type = 'orphan_activations' if params[:orphan_activations]
    include_minor = params[:include_minor] if params[:include_minor]
    include_external = params[:include_external] if params[:include_external]
    qrp = params[:qrp] if params[:qrp]
    if params[:by_day]
      date_query = " || ' ' || time::date"
      date_query_ext = ",' ', date::date"
    end
    if params[:by_year]
      date_query = " || ' ' || date_part('year', time)"
      date_query_ext = ",' ', extract('year' from date)"
    end

    minor_query = include_minor == false ? 'a.minor is not true' : 'true'

    if qrp == true
      qrp_query1 = 'is_qrp1=true'
      qrp_query2 = 'is_qrp2=true'
    end

    if asset_type == 'all'
      ats = AssetType.where(keep_score: true)
      at_list = ats.map { |at| "'" + at.name + "'" }.join(',')
    elsif asset_type == 'everything'
      ats = AssetType.where("name != 'all'")
      at_list = ats.map { |at| "'" + at.name + "'" }.join(',')
    else
      at_list = asset_type.split(',').map { |at| "'" + at.strip + "'" }.join(',')
    end

    codes1 = Contact.find_by_sql [' select distinct(asset1_codes' + date_query + ') as asset1_codes from (select time, unnest(asset1_classes) as asset1_classes, unnest(asset1_codes) as asset1_codes from contacts where user1_id=' + id.to_s + ' and ' + qrp_query1 + ') as c inner join assets a on a.code = c.asset1_codes where a.asset_type in (' + at_list + ") and a.is_active=true and #{minor_query}; "]
    codes2 = Contact.find_by_sql [' select distinct(asset2_codes' + date_query + ') as asset1_codes from (select time, unnest(asset2_classes) as asset2_classes, unnest(asset2_codes) as asset2_codes from contacts where user2_id=' + id.to_s + ' and ' + qrp_query2 + ') as c inner join assets a on a.code = c.asset2_codes where a.asset_type in (' + at_list + ") and a.is_active=true and #{minor_query}; "]
    if include_external == true
      codes3 = ExternalActivation.find_by_sql [' select concat(summit_code' + date_query_ext + ") as summit_code from external_activations where user_id='#{id}' and asset_type in (" + at_list + ');']
    end
    case result_type
    when 'all'
      codes = [codes1.map(&:asset1_codes).join(','), codes2.map(&:asset1_codes).join(','), codes3.map(&:summit_code).join(',')].join(',').split(',').uniq
    when 'only_activator'
      codes = [codes1.map(&:asset1_codes).join(','), codes3.map(&:summit_code).join(',')].join(',').split(',').uniq
    when 'orphan_activations'
      codes1_arr = codes1.map(&:asset1_codes)
      codes2_arr = codes2.map(&:asset1_codes)
      codes = codes2_arr - codes1_arr
    end
    codes.reject(&:empty?)
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
  # NOTE: updated method using qualifed data cached in each log. Will no longer count
  #       activations split over multiple logs
  ##########################################################################################
  def qualified(params = {})
    raise 'asset_type is required in User.qualified' unless params[:asset_type]

    date_query = "'forever'"

    date_query = 'date::date' if params[:by_day]
    date_query = "date_part('year', date)" if params[:by_year]

    minor_query = params[:include_minor] == true ? 'true' : 'a.minor is not true'

    qual_codes = Log.find_by_sql ["
      select distinct concat(als.asset_codes, ' ', #{date_query}) as asset_codes from
        (
          select date,
            unnest(asset_codes) as asset_codes,
            unnest(asset_classes) as asset_classes,
            unnest(qualified) as qualified
          from logs
          where user1_id=#{id}
            and '#{params[:asset_type]}'=ANY(asset_classes)
        ) as als
      inner join assets a on a.code=als.asset_codes
      where als.asset_classes='#{params[:asset_type]}'
        and als.qualified=true
        and #{minor_query};
    "]

    qual_codes2 = []
    if params[:include_external]
      at = AssetType.find_by(name: params[:asset_type])

      qual_codes2 = ExternalActivation.find_by_sql ["
          select distinct concat(summit_code, ' ', " + date_query + ") as summit_code
          from external_activations
          where user_id='#{id}'
            and qso_count>=#{at.min_qso}
            and asset_type='#{params[:asset_type]}';
         "]
    end

    result_codes = qual_codes.map(&:asset_codes)
    result_codes += qual_codes2.map(&:summit_code)
    result_codes.uniq.map { |rc| rc.split(' ')[0] }
  end

  ###########################################################################################
  # Update score fields for this user
  #
  # Returns:
  #   success: boolean
  ###########################################################################################
  def update_score
    ats = AssetType.where('keep_score is not false')
    ats.each do |asset_type|
      include_external = asset_type.name == 'summit'
      score[asset_type.name] = bagged(asset_type: asset_type.name).count
      score_total[asset_type.name] = 0
      activated_count[asset_type.name] = activations(asset_type: asset_type.name, include_external: include_external).count
      activated_count_total[asset_type.name] = activations(by_year: true, asset_type: asset_type.name, include_external: include_external).count
      confirmed_activated_count[asset_type.name] = activations(asset_type: asset_type.name, include_external: include_external, only_activator: true).count
      confirmed_activated_count_total[asset_type.name] = activations(by_year: true, asset_type: asset_type.name, include_external: include_external, only_activator: true).count
      chased_count[asset_type.name] = chased(asset_type: asset_type.name, include_external: include_external).count
      chased_count_total[asset_type.name] = chased(asset_type: asset_type.name, by_day: true, include_external: include_external).count
      qualified_count[asset_type.name] = qualified(asset_type: asset_type.name, include_external: include_external).count
      qualified_count_total[asset_type.name] = qualified(by_year: true, asset_type: asset_type.name, include_external: include_external).count
    end

    qrp = AssetType.new
    qrp.name = 'qrp'
    ats << qrp

    score['qrp'] = bagged(qrp: true).count
    score_total['qrp'] = 0
    activated_count['qrp'] = activations(qrp: true).count
    activated_count_total['qrp'] = activations(qrp: true, by_year: true).count
    chased_count['qrp'] = chased(qrp: true).count
    chased_count_total['qrp'] = chased(qrp: true, by_day: true).count

    score['elevation'] = elevation_bagged(include_external: true)
    qualified_count_total['elevation'] = 0
    activated_count_total['elevation'] = elevation_activated(include_external: true, by_day: true)
    activated_count['elevation'] = elevation_activated(include_external: true)
    chased_count_total['elevation'] = elevation_chased(include_external: true, by_day: true)
    chased_count['elevation'] = elevation_chased(include_external: true)

    score['p2p'] = get_p2p_all.count

    save
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
  def elevation_bagged(params = {})
    elevation = 0
    ats = AssetType.where(has_elevation: true)
    params[:asset_type] = ats.map(&:name).join(',')

    codes = bagged(params)
    codes.each do |code|
      asset = Asset.find_by(code: code)
      elevation += asset.altitude if asset && !asset.altitude.nil?
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
  def elevation_chased(params = {})
    elevation = 0
    ats = AssetType.where(has_elevation: true)
    params[:asset_type] = ats.map(&:name).join(',')

    codes = chased(params)
    codes.each do |code|
      asset = Asset.find_by(code: code.split(' ')[0])
      elevation += asset.altitude if asset && !asset.altitude.nil?
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
  def elevation_qualified(params = {})
    elevation = 0
    ats = AssetType.where(has_elevation: true)
    codes = []
    ats.each do |at|
      params[:asset_type] = at.name
      codes += qualified(params)
    end
    codes.each do |code|
      asset = Asset.find_by(code: code.split(' ')[0])
      elevation += asset.altitude if asset && !asset.altitude.nil?
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
  def elevation_activated(params = {})
    elevation = 0
    ats = AssetType.where(has_elevation: true)
    params[:asset_type] = ats.map(&:name).join(',')

    codes = activations(params)
    codes.each do |code|
      asset = Asset.find_by(code: code.split(' ')[0])
      elevation += asset.altitude if asset && !asset.altitude.nil?
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
  def self.users_with_assets(sortby = 'park', scoreby = 'score', max_rows = 2000)
    User.find_by_sql ["
      select * from users
        where cast(substring(SUBSTRING(" + scoreby + " from '" + sortby + ": [0-9]{1,9}') from ' [0-9]{1,9}') as integer)>0
        and " + scoreby + " not like '%%{}%%'
      order by cast(substring(SUBSTRING(" + scoreby + " from '" + sortby + ": [0-9]{1,9}') from ' [0-9]{1,9}') as integer) desc
      limit " + max_rows.to_s]
  end

  ###########################################################################################
  # List all unique P2P contacts for current user
  # Returns:
  #   p2p: [contact_details] - Array of unique values of "<date> <asset1_code> <asset2_code>"
  #                          from all contacts for this user where one or other asset_code
  #                          is in ZLOTA
  ###########################################################################################
  def get_p2p_all
    # list of all ZLOTA asset types
    ats = AssetType.where(keep_score: true)
    at_list = ats.map { |at| "'" + at.name + "'" }.join(',')

    # contacts where I'm in ZLOTA
    contacts1 = Contact.find_by_sql ["select (time::date || ' ' || split_part(asset1_code,' ', 1) || ' ' || split_part(asset2_code, ' ', 1)) as asset1_code from (select c1.time as time, c1.date as date, c1.id as id, c1.user1_id as user1_id, c1.user2_id as user2_id, unnest(c1.asset1_codes) as asset1_code, unnest(c1.asset1_classes) as asset1_class, asset2_code from contacts c1 join (select id, unnest(asset2_codes) as asset2_code from contacts) c2 on c2.id=c1.id where c1.user1_id=" + id.to_s + ') as foo where asset1_class in (' + at_list + '); ']
    contacts2 = Contact.find_by_sql ["select (time::date || ' ' || split_part(asset1_code, ' ', 1) || ' ' || split_part(asset2_code, ' ', 1)) as asset1_code from (select c1.time as time, c1.date as date, c1.id as id, c1.user1_id as user1_id, c1.user2_id as user2_id, unnest(c1.asset2_codes) as asset1_code, unnest(c1.asset2_classes) as asset1_class, asset2_code from contacts c1 join (select id, unnest(asset1_codes) as asset2_code from contacts) c2 on c2.id=c1.id where c1.user2_id=" + id.to_s + ') as foo where asset1_class in (' + at_list + '); ']
    # contacts where other party  ZLOTA (reverse code order so my loc first
    # to avoid double-counting ZLOTA-ZLOTA
    contacts3 = Contact.find_by_sql ["select (time::date || ' ' || split_part(asset2_code,' ', 1) || ' ' || split_part(asset1_code, ' ', 1)) as asset1_code from (select c1.time as time, c1.date as date, c1.id as id, c1.user1_id as user1_id, c1.user2_id as user2_id, unnest(c1.asset1_codes) as asset1_code, unnest(c1.asset1_classes) as asset1_class, asset2_code from contacts c1 join (select id, unnest(asset2_codes) as asset2_code from contacts) c2 on c2.id=c1.id where c1.user2_id=" + id.to_s + ') as foo where asset1_class in (' + at_list + '); ']
    contacts4 = Contact.find_by_sql ["select (time::date || ' ' || split_part(asset2_code, ' ', 1) || ' ' || split_part(asset1_code, ' ', 1)) as asset1_code from (select c1.time as time, c1.date as date, c1.id as id, c1.user1_id as user1_id, c1.user2_id as user2_id, unnest(c1.asset2_codes) as asset1_code, unnest(c1.asset2_classes) as asset1_class, asset2_code from contacts c1 join (select id, unnest(asset1_codes) as asset2_code from contacts) c2 on c2.id=c1.id where c1.user1_id=" + id.to_s + ') as foo where asset1_class in (' + at_list + '); ']
    (contacts1 + contacts2 + contacts3 + contacts4).map(&:asset1_code).uniq
  end

  ##################################################################################
  # WRAPPERS
  ##################################################################################

  def self.all_activations
    codes = Contact.find_by_sql [" select distinct code from (
           (select unnest(asset1_codes) as code from contacts c1)
          union
           (select unnest(asset2_codes) as code from contacts c2)
          union
           (select summit_code as code from external_activations c3)
          ) as c; "]
    codes.map { |c| c[:code] }
  end

  def self.all_chases
    codes = Contact.find_by_sql [" select distinct code from (
            (select unnest(asset1_codes) as code from contacts c1)
           union
            (select unnest(asset2_codes) as code from contacts c2)
           union
            (select summit_code as code from external_chases c3)
           ) as c; "]
    codes.map { |c| c[:code] }
  end

  ##################################################################################
  # Single function to call activated / bagged / chased based on parameters passed
  # Input:
  #   asset_type: AssetType.name or 'qrp'
  #   count_type: 'activated' or 'chased' or 'bagged'
  #   include_minor: true / false - include minor assets in list
  # Returns:
  #   codes: array of [Asset.code]
  ##################################################################################
  def assets_by_type(asset_type, count_type, include_minor = false)
    include_external = (asset_type == 'summit') || (asset_type == 'pota park') ? true : false
    codes = if asset_type == 'qrp'
              case count_type
              when 'activated'
                activations(qrp: true, include_minor: include_minor)
              when 'chased'
                chased(qrp: true, include_minor: include_minor)
              else
                bagged(qrp: true, include_minor: include_minor)
              end
            else
              case count_type
              when 'activated'
                activations(asset_type: asset_type, include_minor: include_minor, include_external: include_external)
              when 'chased'
                chased(asset_type: asset_type, include_minor: include_minor, include_external: include_external)
              else
                bagged(asset_type: asset_type, include_minor: include_minor, include_external: include_external)
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
  def wwff_logs(resubmit = false)
    resubmit_str = resubmit == true ? '' : ' and submitted_to_wwff is not true'
    wwff_logs = []
    logger.debug 'resubmit: ' + resubmit_str

    contacts2 = Contact.find_by_sql ['select distinct asset1_codes  from (select distinct unnest(asset1_codes) as asset1_codes  from contacts where user1_id = ' + id.to_s + '' + resubmit_str + " and 'wwff park'=ANY(asset1_classes)) as sq where asset1_codes like 'ZLFF-%%'"]
    references = contacts2.map(&:asset1_codes)

    # get list of contacts for each park
    references.each do |park|
      pp = Asset.find_by(code: park)
      next unless pp
      # all contacts for this user from this park
      contacts1 = Contact.find_by_sql ['select distinct callsign2, date::date as date, band, mode from contacts where  user1_id = ? and (? = ANY(asset1_codes)) and (date >= ?)' + resubmit_str, id, park, pp.valid_from]
      contacts = []
      dups = []

      # for each unique chaser / date / mode / band combination
      # add 1st matching contacts to valid list
      # and add remainder to duplicates list
      contacts1.each do |c|
        contacts2 = Contact.find_by_sql [' select * from contacts where user1_id= ? and callsign2 = ? and band = ? and mode = ? and date::date = ? and (? = ANY(asset1_codes))' + resubmit_str + ' order by time asc;', id, c.callsign2, c.band, c.mode, c.date.strftime('%Y-%m-%d'), park]
        if contacts2 && contacts2.count.positive?
          contacts.push(contacts2.first)
          dups += contacts2[1..-1] if contacts2.count > 1
        end
      end

      if contacts.count > 0 then wwff_logs.push(park: { name: pp.name, wwffpark: pp.code }, count: contacts.uniq.count, contacts: contacts.uniq.sort_by(&:date), dups: dups.uniq) end
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
  def sota_logs(summit_code = nil, merge = false)
    if summit_code.nil?
      summit_query1 = "'summit'=ANY(asset1_classes)"
      summit_query2 = "c1.asset1_classes='summit'"
    else
      summit_query1 = "'#{summit_code}'=ANY(asset1_codes)"
      summit_query2 = "c1.asset1_codes='#{summit_code}'"
    end

    sota_logs = Contact.find_by_sql ["
        select a.name, a.safecode, c3.* from
          (select asset1_codes as code, date, min(time) as time,
            count(case submitted_to_sota when true then 1 else null end) as submitted,
            count(date) as count
            from
              (select callsign1, callsign2, date::date as date, time, asset1_codes, submitted_to_sota from
                 (select callsign1, callsign2, date,  time,
                    unnest(asset1_classes) as asset1_classes,
                    unnest(asset1_codes) as asset1_codes,
                    submitted_to_sota
                    from contacts
                    where user1_id=#{id} and #{summit_query1}) as c1
                 where #{summit_query2}) as c2
            group by asset1_codes, date
            order by min(time)) as c3
          inner join assets a on a.code=c3.code;
      "]
    # now find activtions continuing into new day and combine unless they are in a new year
    if merge == true
      count = 1
      while count < sota_logs.count
        if sota_logs[count] && (sota_logs[count].safecode == sota_logs[count - 1].safecode) && (sota_logs[count].time <= sota_logs[count - 1].time + 1.days) && (sota_logs[count].time.strftime('%Y') == sota_logs[count - 1].time.strftime('%Y'))
          # drop this log, add contacts to last
          sota_logs[count - 1].count += sota_logs[count].count
          sota_logs.delete_at(count)
        end
        count += 1
      end
    end
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
  def sota_chaser_contacts(summit_code = nil, resubmit = false)
    sota_logs = []
    submitted_clause = if resubmit == false
                         ' and submitted_to_sota is not true'
                       else
                         ''
                       end

    summit_clause = if summit_code
                      "and '#{summit_code}' = ANY(c1.asset2_codes)"
                    else
                      "and 'summit'=ANY(c1.asset2_classes)"
                    end

    chaser_contacts = Contact.find_by_sql ["
         select * from (
           select id, log_id, callsign1, callsign2, mode, frequency, band, is_portable1,
             is_portable2, date, time, asset1_codes, asset1_classes,
             unnest(c1.asset2_classes) as asset2_classes,
             unnest(c1.asset2_codes) as asset2_codes
             from contacts c1
             where c1.user1_id='#{id}'
               and not ('summit'=ANY(c1.asset1_classes))
               #{summit_clause}
               #{submitted_clause}
         ) as c2
         where c2.asset2_classes='summit'
         order by c2.time asc; "]

    sota_logs[0] = { code: nil, date: nil, count: chaser_contacts.count, contacts: chaser_contacts }

    sota_logs
  end

  #################################################################################
  # Return array of sota_logs, including contacts for all or specified summit
  # for this user
  # Returns:
  #  sota_contacts: Array containing one log and multiple contacts
  #    [
  #       code: summit_code
  #       date: activationDate
  #       count: integer - count of valid contacts in this log
  #       contacts: Array of [Contact]
  #    ]
  ###############################################################################
  def sota_contacts(summit_code = nil, merge = true)
    sota_contacts = []
    sota_logs = self.sota_logs(summit_code)

    sota_logs.each do |sota_log|
      contacts = Contact.where('user1_id = ? and ? = ANY(asset1_codes) and date::date= ?', id, sota_log[:code], sota_log[:date].strftime('%Y-%m-%d')).order(:time)
      contact_count = contacts.count
      sota_contacts.push(code: sota_log[:code], date: sota_log[:date], time: sota_log[:time], count: contact_count, contacts: contacts)
    end
    # now find activtions continuing into new day and combine
    if merge == true
      count = 1
      while count < sota_contacts.count
        if (sota_contacts[count][:code] == sota_contacts[count - 1][:code]) && (sota_contacts[count][:time] <= sota_contacts[count - 1][:time] + 1.days) && (sota_contacts[count][:time].strftime('%Y') == sota_contacts[count - 1][:time].strftime('%Y'))
          # drop this log, add contacts to last
          sota_contacts[count - 1][:count] += sota_contacts[count][:count]
          sota_contacts[count - 1][:contacts] += sota_contacts[count][:contacts]
          sota_contacts.delete_at(count)

        end
        count += 1
      end
    end

    sota_contacts.compact
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
  def pota_logs(park_code = nil)
    if park_code.nil?
      park_query1 = "'pota park'=ANY(asset1_classes)"
      park_query2 = "c1.asset1_classes='pota park'"
    else
      park_query1 = "'#{park_code}'=ANY(asset1_codes)"
      park_query2 = "c1.asset1_codes='#{park_code}'"
    end

    pota_logs = Contact.find_by_sql ["
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
                    where user1_id=#{id} and #{park_query1}) as c1
                 where #{park_query2}) as c2
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
  def pota_contacts(park_code = nil)
    pota_contacts = []
    pota_logs = self.pota_logs(park_code)

    pota_logs.each do |pota_log|
      contacts = Contact.where('user1_id = ? and ? = ANY(asset1_codes) and date::date= ?', id, pota_log[:code], pota_log[:date].strftime('%Y-%m-%d'))
      contact_count = contacts.count
      pota_contacts.push(code: pota_log[:code], date: pota_log[:date], count: contact_count, contacts: contacts.sort_by(&:date))
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
  def area_activations(scope, include_minor = false)
    minor_query = include_minor == false ? 'a.minor is not true' : 'true'

    Contact.find_by_sql ["
      select array_agg(DISTINCT asset1_code) as site_list,
        a.asset_type as type, a.#{scope} as name
      from
        (
          (
            select date, unnest(asset1_codes) as asset1_code
            from contacts c
            where user1_id=" + id.to_s + "
          ) union (
            select date, unnest(asset2_codes) as asset1_code
            from contacts
            where user2_id=" + id.to_s + "
          ) union (
            select date, summit_code as asset1_code
            from external_activations
            where user_id=" + id.to_s + "
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
  def area_chases(scope, include_minor = false)
    minor_query = include_minor == false ? 'a.minor is not true' : 'true'

    Contact.find_by_sql ["
      select array_agg(DISTINCT asset1_code) as site_list,
        a.asset_type as type, a.#{scope} as name
      from
        (
          (
            select date, unnest(asset2_codes) as asset1_code
            from contacts c
            where user1_id=" + id.to_s + "
          ) union (
            select date, unnest(asset1_codes) as asset1_code
            from contacts
            where user2_id=" + id.to_s + "
          ) union (
            select date, summit_code as asset1_code
            from external_chases
            where user_id=" + id.to_s + "
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
    uas = AwardUserLink.find_by_sql [' select * from award_user_links where user_id = ' + id.to_s + " and award_type='" + scope + "' and linked_id=" + loc_id.to_s + " and activity_type='" + activity_type + "' and award_class='" + award_class + "' and expired is not true "]
    uas && uas.count.positive? ? true : false
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
    uas = AwardUserLink.find_by_sql [' select * from award_user_links where user_id = ' + id.to_s + " and award_type='" + scale + "' and linked_id=" + loc_id.to_s + " and activity_type='" + activity_type + "' and award_class='" + award_class + "' and expired is not true "]
    uas.each do |ua|
      logger.warn 'Retiring ' + callsign + ' ' + loc_id.to_s + ' ' + scale + ' ' + activity_type + ' ' + award_class
      ua.expired = true
      ua.expired_at = Time.now
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
    award = nil
    if activity_type == 'chaser'
      chased = true
      activated = false
    elsif activity_type == 'activator'
      chased = false
      activated = true
    end
    award_spec = Award.find_by(chased: chased, activated: activated, programme: award_class, 'all_' + scope => true, is_active: true)
    if award_spec && !has_completion_award(scope, loc_id, activity_type, award_class)
      logger.debug 'Awarded!! ' + callsign + ' ' + award_class + ' ' + scope + ' ' + activity_type + ' ' + loc_id.to_s
      award = AwardUserLink.new
      award.award_type = scope
      award.linked_id = loc_id
      award.activity_type = activity_type
      award.award_class = award_class
      award.user_id = id
      award.award_id = award_spec.id
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
    if scope == 'district'
      modelname = District
      indexfield = 'district_code'
    elsif scope == 'region'
      modelname = Region
      indexfield = 'sota_code'
    else
      raise 'Invalid scope for area award: ' + scope.to_s
    end

    avail = modelname.get_assets_with_type
    activations = area_activations(scope)
    chases = area_chases(scope)
    avail.each do |combo|
      activation = activations.select { |a| (a.name == combo.name) && (a.type == combo.type) }
      chase = chases.select { |c| (c.name == combo.name) && (c.type == combo.type) }
      if activation && activation.count.positive?
        site_not_act = (combo.site_list - activation.first.site_list).count
        d = modelname.find_by(indexfield => combo.name)
        if site_not_act.zero?
          # issue award if not already issued
          issue_completion_award(scope, d.id, 'activator', combo.type)
        else
          # check for expired award
          retire_completion_award(scope, d.id, 'activator', combo.type)
        end
      end

      next unless chase && chase.count.positive?
      site_not_chased = (combo.site_list - chase.first.site_list).count
      d = modelname.find_by(indexfield => combo.name)
      if site_not_chased.zero?
        # issue award if not already issued
        issue_completion_award(scope, d.id, 'chaser', combo.type)
      else
        # check for expired award
        retire_completion_award(scope, d.id, 'chaser', combo.type)
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
  def has_award(award_id, threshold = nil)
    awarded = { status: false, latest: nil, next: nil }
    score = 0
    awls = AwardUserLink.find_by_sql [' select * from award_user_links where user_id=' + id.to_s + ' and award_id=' + award_id.to_s + ' order by threshold desc limit 1']
    if awls && (awls.count == 1)
      awarded[:latest] = awls.first.threshold_name.capitalize + ' (' + awls.first.threshold.to_s + ')'
      score = awls.first.threshold
      awarded[:status] = true if (score == threshold) || threshold.nil?
    end
    if score
      next_threshold = AwardThreshold.find_by_sql [' select * from award_thresholds where threshold>' + score.to_s + ' order by threshold asc limit 1']
      if next_threshold && (next_threshold.count == 1)
        awarded[:next] = next_threshold.first.name.capitalize + ' (' + next_threshold.first.threshold.to_s + ')'
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
    unless has_award(award_id, threshold)[:status]
      a = AwardUserLink.new
      a.award_id = award_id
      a.threshold = threshold
      a.award_type = 'threshold'
      a.user_id = id
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
  def check_awards
    user = self
    awards = Award.where(is_active: true)
    awards.each do |award|
      next if user.has_award(award.id, nil)[:status]
      next unless award.count_based == true
      if (award.activated == true) && (award.chased == true)
      # this is where completed awards would go, when the code supports them!
      elsif award.activated == true
        score = user.qualified_count_total[award.programme]
      elsif award.chased == true
        score = user.chased_count_total[award.programme]
      else
        score = user.score[award.programme]
      end
      next unless score
      AwardThreshold.all.each do |threshold|
        if score >= threshold.threshold
          user.issue_award(award.id, threshold.threshold)
        end
      end
    end
  end

  ###############################################################################
  # CALLSIGN HANDLING
  ###############################################################################

  #############################################################################################
  # Return the callsign segment of a call with prefix / suffix
  #############################################################################################
  def self.remove_call_suffix(callsign)
    theseg = nil
    maxlen = 0
    segs = callsign.split('/')
    # try each segment and choose 1st that matches valid callsign pattern
    segs.each do |seg|
      theseg = seg if VALID_CALLSIGN_REGEX.match(seg)
    end

    unless theseg
      # try each part and choose longest
      segs.each do |seg|
        if seg.length > maxlen
          theseg = seg
          maxlen = seg.length
        end
      end
    end
    theseg
  end

  ###############################################################################
  # Create userCallsign entries for current user, if missing
  ###############################################################################
  def add_callsigns
    dup = UserCallsign.where(user_id: id, callsign: callsign)
    if !dup || dup.count.zero?
      uc = UserCallsign.new
      uc.user_id = id
      uc.from_date = Time.new(1900, 1, 1)
      uc.callsign = callsign
      uc.save
      logger.debug 'Added: ' + callsign
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
  def self.find_by_callsign_date(callsign, c_date, create = false)
    ucs = UserCallsign.find_by_sql [' select * from user_callsigns where callsign=? and from_date<=? and (to_date is null or to_date>=?) ', callsign, c_date, c_date]
    uc = nil
    if ucs && ucs.count.positive?
      uc = ucs.first.user
    elsif create == true
      uc = User.create_dummy_user(callsign)
    end
    uc
  end

  ###############################################################################
  # Check if a callsign exists.
  # If not, Create a 'dummy' user for that callsign, giving no login rights
  # Returns:
  # - user: [User] or nil if call already exists
  ###############################################################################
  def self.create_dummy_user(callsign)
    dup = UserCallsign.find_by(callsign: callsign)
    unless dup
      logger.debug 'Create callsign: ' + callsign
      User.create(callsign: callsign, activated: false, password: 'dummy', password_confirmation: 'dummy', timezone: 1)
    end
  end

  ###############################################################################
  # Update logs / contacts for specific callsign to new user using that call on
  # dates they own that callsign
  # - called after new callsign added, or dates on callsign changed
  ###############################################################################
  def self.reassign_userids_used_by_callsign(callsign)
    ls = Log.find_by_sql ['select * from logs where callsign1=?', callsign]
    ls.each(&:save)

    # only callsign2 as callsign1 picked up by logs (above)
    cs = Contact.find_by_sql [' select * from contacts where callsign2=?', callsign]
    cs.each(&:save)

    sas = ExternalActivation.find_by_sql ['select * from external_activations where callsign=?', callsign]
    sas.each(&:save)

    scs = ExternalChase.find_by_sql ['select * from external_chases where callsign=?', callsign]
    scs.each(&:save)
  end

  ##########################################################################
  # ADMIN TOOLS - COMMAND-LINE USE ONLY
  ##########################################################################

  ###############################################################################
  # Update score for all users - called only from console
  ###############################################################################
  def self.update_scores
    users = User.all
    users.each do |user|
      puts user.callsign
      user.update_score
    end
  end

  ###############################################################################
  # Re-build callsigns table for all user's primary callsigns
  ###############################################################################
  def self.add_all_callsigns
    us = User.all
    us.each(&:add_callsigns)
  end

  private

  def create_remember_token
    self.remember_token = User.digest(User.new_token)
  end

  def downcase_email
    self.email = email.downcase
  end
end
