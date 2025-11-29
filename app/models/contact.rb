# frozen_string_literal: true

# typed: false
class Contact < ActiveRecord::Base
  after_initialize :set_defaults, unless: :persisted?
  # The set_defaults will only work if the object is new
  attr_accessor :timetext
  attr_accessor :asset2_names

  belongs_to :createdBy, class_name: 'User'

  before_save { before_save_actions }
  after_save { update_scores }
  before_destroy { update_scores }

  validates :callsign1,  presence: true, length: { maximum: 50 }
  validates :callsign2,  presence: true, length: { maximum: 50 }

  def before_save_actions
    remove_call_suffix
    self.callsign1 = UserCallsign.clean(callsign1)
    self.callsign2 = UserCallsign.clean(callsign2)
    add_user_ids
    check_codes_in_location
    location = get_most_accurate_location(true)
    add_containing_codes(location[:asset]) if !do_not_lookup == true

    check_for_same_place_error # again incase they match after adding child codes
    update_classes
    self.band = band_from_frequency
  end

  #####################################################################
  # CALCULATED PARAMETERS
  #####################################################################
  def log
    Log.find_by(id: log_id)
  end

  # [asset1.code] asset1.name ... || loc_desc1+ {x,y}
  def location1_text
    text = ''
    activator_assets.each do |al|
      text += al.codename + ' '
    end

    if text == ''
      text = loc_desc1 if loc_desc1
      text += ' (E' + x1.to_s + ' N' + y1.to_s + ')' if x1 && y1
    end
    text
  end

  # [asset2.code] asset2.name ... || loc_desc2+ {x,y}
  def location2_text
    text = ''
    chaser_assets.each do |al|
      text += al.codename + ' '
    end

    if text == ''
      text = loc_desc2 if loc_desc2
      text += ' (E' + x2.to_s + ' N' + y2.to_s + ')' if x2 && y2
    end
    text
  end

  # array of activator assets
  def activator_asset
    cals = []
    asset1_codes.each do |code|
      cal = Asset.find_by(code: code)
      cals.push(cal)
    end
    cals
  end

  # array of chaser assets
  def chaser_assets
    cals = []
    asset2_codes.each do |code|
      cal = Asset.find_by(code: code)
      cals.push(cal)
    end
    cals
  end

  # user1
  def user1
    user = User.find_by_id(user1_id)
    user.first
  end

  # user2
  def user2
    user = User.find_by_id(user2_id)
    user.first
  end

  # name of timezone contact saved in
  def timezonename
    timezonename = ''
    if timezone != ''
      tz = Timezone.find_by_id(timezone)
      timezonename = tz.name if tz
    end
    timezonename
  end

  # convert contact.date to user's selected timezone
  def localdate(current_user)
    t = nil
    tz = current_user ? Timezone.find_by_id(current_user.timezone) : Timezone.find_by(name: 'UTC')
    t = time.in_time_zone(tz.name).strftime('%Y-%m-%d') if time
    t
  end

  # convert contact.time to user's selected timezone
  def localtime(current_user)
    t = nil
    tz = current_user ? Timezone.find_by_id(current_user.timezone) : Timezone.find_by(name: 'UTC')
    t = time.in_time_zone(tz.name).strftime('%H:%M') if time
    t
  end

  # text name for user's timezone, defaulting to UTC if no user
  def localtimezone(current_user)
    t = nil
    tz = current_user ? Timezone.find_by_id(current_user.timezone) : Timezone.find_by(name: 'UTC')
    t = time.in_time_zone(tz.name).strftime('%Z') if time
    t
  end

  # return ADIF-compatable mode closest to that specified in contact
  def adif_mode
    mode = 'OTHER'
    rawmode = self.mode.upcase
    rawmode = 'SSB' if rawmode[0..2] == 'LSB'
    rawmode = 'SSB' if rawmode[0..2] == 'USB'
    rawmode = 'SSB' if rawmode[0..2] == 'SSB'
    found = false
    found = true if rawmode == 'AM'
    found = true if rawmode == 'CW'
    found = true if rawmode == 'FM'
    found = true if rawmode == 'SSB'
    found = true if rawmode == 'DSTAR'
    found = true if rawmode == 'FT8'
    found = true if rawmode == 'FT4'
    found = true if rawmode == 'JS8'

    mode = rawmode if found == true
    mode = 'FT8' if rawmode == 'DATA'
    mode
  end

  # return band name (wavelength band) for contact's frequency
  def band_from_frequency
    self.band = Contact.band_from_frequency(frequency)
  end

  # return hema name (frequency band) for contact's frequency
  def hema_band
    Contact.hema_band_from_frequency(frequency)
  end

  #####################################################################
  # ON SAVE ACTIONS
  #####################################################################
  def set_defaults
    self.timezone ||= Timezone.find_by(name: 'UTC').id
  end

  def remove_call_suffix # and prefix
    self.callsign1 = User.remove_call_suffix(callsign1) if callsign1['/']
    self.callsign2 = User.remove_call_suffix(callsign2) if callsign2['/']
  end

  # look up usersids for the callsign on the contact date, create dummy user if not found
  # (all contacts must have a user)
  def add_user_ids
    # look up callsign1 at contact.time
    user1 = User.find_by_callsign_date(callsign1, time, true)
    self.user1_id = user1.id if user1
    # look up callsign2 at contact.time
    user2 = User.find_by_callsign_date(callsign2, time, true)
    self.user2_id = user2.id if user2
  end

  # extract asset2_codes from loc_desc2 text field but only if asset2_codes is blank
  def check_codes_in_location
    if asset2_codes.nil? || (asset2_codes == []) || (asset2_codes == [''])
      self.asset2_codes = Asset.check_codes_in_text(loc_desc2)
    end
    if asset2_codes.nil? || (asset2_codes == []) || (asset2_codes == [''])
      self.asset2_codes = Asset.check_codes_in_text(comments2)
    end
  end

  # do not allow activator & chaser to be in same place
  # - silently remove chaser location if this happens
  # - better than failing a log upload or save where we have not ability to display error
  def check_for_same_place_error
    if asset1_codes and asset1_codes!=[] and asset1_codes.sort == asset2_codes.sort
      logger.debug 'Removing invalid asset2 codes'
      self.asset2_codes = []
      self.loc_desc2 = 'INVALID'
    end
  end

  # look up child codes for asset2 using either location (ZL) or lookup-table (VK)
  def get_all_asset2_codes(asset)
    codes = asset2_codes
    newcodes = codes
    if location2 and loc_source2!="unreliable" then newcodes += Asset.containing_codes_from_location(location2, asset) end
    codes.each do |code|
      newcodes += VkAsset.containing_codes_from_parent(code)
    end
    newcodes.uniq
  end

  # update asset#_classes arrays to show asset type for all asset#_codes - in order
  def update_classes
    asset1_classes = []
    asset1_codes.each do |code|
      asset = Asset.assets_from_code(code)
      asset1_classes.push(asset.first[:type]) if asset && asset.count.positive?
    end
    self.asset1_classes = asset1_classes

    asset2_classes = []
    asset2_codes.each do |code|
      asset = Asset.assets_from_code(code)
      asset2_classes.push(asset.first[:type]) if asset && asset.count.positive?
    end
    self.asset2_classes = asset2_classes
  end

  # add child asset#_codes for both parties
  def add_containing_codes(asset)
    # just inherit log codes for assets1
    self.asset1_codes = log.asset_codes if log

    # then lookup codes for assets2
    # replace supplied replaced codes with new master codes
    self.asset2_codes = Asset.find_master_codes(asset2_codes)
  
    # look up contained_by_assets
    self.asset2_codes = get_all_asset2_codes(asset)
  end

  # update location1 and location2 to use most accurate location we have.
  # preference logic:
  # user supplied => point based asset => area based asset (smallest area)
  def get_most_accurate_location(force = false)
    # just inherit location1 from log
    self.location1 = log.location1 if log

    # location2
    location = { location: location2, source: loc_source2, asset: nil }

    self.loc_source2 = nil if location2.nil?

    # for anything other than a user specified location
    if loc_source2 != 'user'
      # only overwrite a location when asked to
      if location2 && (force == true)
        self.loc_source2 = nil
        self.location2 = nil
      end

      # lookup location for asset2 by finding most accurate asset2 location
      location = Asset.get_most_accurate_location(asset2_codes, location[:source], location[:location])
      self.loc_source2 = location[:source]
      self.location2 = location[:location]
    end
    location
  end

  # trigger score and award updates for both parties to this contact
  def update_scores
    if user1_id
      user = User.find_by_id(user1_id)
      if user
        log.update_qualified if log
        if Rails.env.production?
          user.outstanding = true
          user.save
          Resque.enqueue(Scorer)
        elsif Rails.env.development?
          user.update_score
          user.check_awards
          user.check_completion_awards('region')
          user.check_completion_awards('district')
        else
          logger.debug 'Not updating score for test env call manually if needed'
        end
      end
    end
    if user2_id
      user = User.find_by_id(user2_id)
      if user
        if Rails.env.production?
          user.outstanding = true
          user.save
          Resque.enqueue(Scorer)
        elsif Rails.env.development?
          user.update_score
          user.check_awards
          user.check_completion_awards('region')
          user.check_completion_awards('district')
        else
          logger.debug 'Not updating score for test env call manually if needed'
        end
        user.check_awards
      end
    end
  end

  ###########################################################
  # HELPER ROUTINES
  ###########################################################
  # create a log for current (unsaved) contact and return the log
  def create_log
    log = Log.new
    log.callsign1 = callsign1
    log.date = date
    log
  end

  # Check if a log exists matching a contact with no log
  # - if it does, add contact to log
  # - if it doesn't, create lg for contact and add it
  #
  # If called with reverse=true:
  # - creates a new activator contact from provided chaser contact, then
  #   associates with log as above
  def find_create_log_matching_contact(do_reverse = false)
    if do_reverse
      contact = reverse
      contact.id = nil
      contact.log_id = nil
      contact.save
    else
      contact = self
    end

    if contact.log_id
      logger.error 'Should not call find_create_log_matching_contact for a contact already in a log'
    else
      # use only the most accrate location when searching for log
      # as chaser may not have included the parks, islands etc to go with
      # a summit
      asset_search = Asset.get_most_accurate_location(contact.asset1_codes)
      if asset_search && asset_search[:asset] then asset = Asset.find_by(id: asset_search[:asset].id) end
      if asset
        dup = Log.find_by("callsign1='#{callsign1}' and date::date='#{contact.date.to_date}' and '#{asset.code}'=ANY(asset_codes)")
        if dup
          # now check the log does not list other more accturate locations
          dup_loc = Asset.get_most_accurate_location(dup.asset_codes)
          # if so, do not match
          dup = nil if dup_loc[:asset].id != asset.id
        end
      else
        # must be an overseas or mistyped asset code so just
        # match on the full set of codes given rather than finding the most
        # accurate
        dup = Log.find_by_sql [" select l.* from logs l inner join contacts c on c.id=#{contact.id} where l.callsign1=c.callsign1 and l.date::date=c.date::date and (l.asset_codes <@ c.asset1_codes and l.asset_codes @> c.asset1_codes); "]
        dup = dup.first
      end
      if dup
        log = dup
        logger.debug 'Reuse log'
      else
        logger.debug 'New log'
        log = Log.create(callsign1: contact.callsign1, date: contact.date, asset_codes: contact.asset1_codes, is_qrp1: contact.is_qrp1, is_portable1: contact.is_portable1, location1: contact.location1, power1: contact.power1)
      end
      contact.log_id = log.id
      contact.save
    end
    contact
  end

  # wrapper for the above to confirm a chaser contact into an activator log
  def confirm_chaser_contact
    find_create_log_matching_contact(true)
  end

  # Remove asset2_codes from a contact at other party's request
  def refute_chaser_contact
    if asset2_codes && asset2_codes.count.positive?
      self.loc_desc2 = 'Removed: ' + asset2_codes.to_s + ' at ' + callsign2 + "'s request"
      self.asset2_codes = []
      self.location2 = nil
      save
    end
  end

  # Return a dulicate (unsaved) contact with the parties reversed from the
  # current contact (returned contact is to be used in memory, not to be saved)
  def reverse
    c = dup
    c.name1 = name2
    c.name2 = name1
    c.callsign1 = callsign2
    c.callsign2 = callsign1
    c.power1 = power2
    c.power2 = power1
    c.signal1 = signal2
    c.signal2 = signal1
    c.comments1 = comments2
    c.comments2 = comments1
    c.loc_desc1 = loc_desc2
    c.loc_desc2 = loc_desc1
    c.x1 = x2
    c.x2 = x1
    c.y1 = y2
    c.y2 = y1
    c.altitude1 = altitude2
    c.altitude2 = altitude1
    c.location1 = location2
    c.location2 = location1
    c.is_qrp1 = is_qrp2
    c.is_qrp2 = is_qrp1
    c.is_portable1 = is_portable2
    c.is_portable2 = is_portable1
    c.user1_id = user2_id
    c.user2_id = user1_id
    c.asset1_codes = asset2_codes
    c.asset2_codes = asset1_codes
    c.asset1_classes = asset2_classes
    c.asset2_classes = asset1_classes
    c.id = -id
    c
  end

  # convert supplied date / time from user's timezone to UTC
  def convert_user_timezone_to_utc(user)
    if time && date
      tz = user ? Timezone.find_by_id(user.timezone) : Timezone.find_by(name: 'UTC')
      t = (date.strftime('%Y-%m-%d') + ' ' + time.strftime('%H:%M')).in_time_zone(tz.name)
      self.date = t.in_time_zone('UTC').strftime('%Y-%m-%d')
      self.time = t.in_time_zone('UTC')
      self.timezone = Timezone.find_by(name: 'UTC').id
    end
  end

  # return details of asset for first asset2_code in current contact that matches supplied type
  # { asset: Asset, code: <code>, ...}
  def find_asset2_by_type(asset_type)
    asset2 = nil
    asset_codes = asset2_codes
    asset_codes.each do |asset_code|
      next unless asset_code
      asset = Asset.assets_from_code(asset_code)
      if asset && asset.count.positive? && (asset.first[:type] == asset_type)
        asset2 = asset.first
      end
    end
    asset2
  end

  # get the contact underlying a p2p (portable-to-portable) entry
  def self.find_contact_from_p2p(user_id, asset1_code, asset2_code, date)
    contact = Contact.find_by("user1_id=#{user_id} and '#{asset1_code}'=ANY(asset1_codes) and '#{asset2_code}'=ANY(asset2_codes) and date>='#{date}'::date and date<('#{date}'::date+'1 day'::interval)")
    contact ||= Contact.find_by("user2_id=#{user_id} and '#{asset1_code}'=ANY(asset2_codes) and '#{asset2_code}'=ANY(asset1_codes) and date>='#{date}'::date and date<('#{date}'::date+'1 day'::interval)")
    contact
  end

  # convert supplied frequency to meter-band
  def self.band_from_frequency(frequency)
    band = ''
    if frequency
      band = '2190m' if (frequency >= 0.136) && (frequency <= 0.137)
      band = '560m' if (frequency >= 0.501) && (frequency <= 0.504)
      band = '160m' if (frequency >= 1.8) && (frequency <= 2)
      band = '80m' if (frequency >= 3.5) && (frequency <= 4)
      band = '60m' if (frequency >= 5.351) && (frequency <= 5.367)
      band = '40m' if (frequency >= 7) && (frequency <= 7.3)
      band = '30m' if (frequency >= 10.1) && (frequency <= 10.15)
      band = '20m' if (frequency >= 14.0) && (frequency <= 14.35)
      band = '17m' if (frequency >= 18.068) && (frequency <= 18.168)
      band = '15m' if (frequency >= 21.0) && (frequency <= 21.45)
      band = '12m' if (frequency >= 24.89) && (frequency <= 24.99)
      band = '10m' if (frequency >= 28.0) && (frequency <= 29.7)
      band = '6m' if (frequency >= 50) && (frequency <= 54)
      band = '4m' if (frequency >= 70) && (frequency <= 71)
      band = '2m' if (frequency >= 144) && (frequency <= 148)
      band = '1.25m' if (frequency >= 222) && (frequency <= 225)
      band = '70cm' if (frequency >= 420) && (frequency <= 450)
      band = '33cm' if (frequency >= 902) && (frequency <= 928)
      band = '23cm' if (frequency >= 1240) && (frequency <= 1300)
      band = '13cm' if (frequency >= 2300) && (frequency <= 2450)
      band = '9cm' if (frequency >= 3300) && (frequency <= 3500)
      band = '6cm' if (frequency >= 5650) && (frequency <= 5925)
      band = '3cm' if (frequency >= 10_000) && (frequency <= 10_500)
      band = '1.25cm' if (frequency >= 24_000) && (frequency <= 24_250)
      band = '6mm' if (frequency >= 47_000) && (frequency <= 47_200)
      band = '4mm' if (frequency >= 75_500) && (frequency <= 81_000)
      band = '2.5mm' if (frequency >= 119_980) && (frequency <= 120_020)
      band = '2mm' if (frequency >= 142_000) && (frequency <= 149_000)
      band = '1mm' if (frequency >= 241_000) && (frequency <= 250_000)
    end
    band
  end

  # convert the supplied meter-band to bottom-band-edge frequency
  def self.frequency_from_band(band)
    band = band.downcase
    frequency = nil
    frequency = 0.136 if band == '2190m'
    frequency = 0.501 if band == '560m'
    frequency = 1.8 if band == '160m'
    frequency = 3.5 if band == '80m'
    frequency = 5.3515 if band == '60m'
    frequency = 7 if band == '40m'
    frequency = 10.1 if band == '30m'
    frequency = 14.0 if band == '20m'
    frequency = 18.068 if band == '17m'
    frequency = 21.0 if band == '15m'
    frequency = 24.89 if band == '12m'
    frequency = 28.0 if band == '10m'
    frequency = 50 if band == '6m'
    frequency = 70 if band == '4m'
    frequency = 144 if band == '2m'
    frequency = 222 if band == '1.25m'
    frequency = 420 if band == '70cm'
    frequency = 902 if band == '33cm'
    frequency = 1240 if band == '23cm'
    frequency = 2300 if band == '13cm'
    frequency = 3300 if band == '9cm'
    frequency = 5650 if band == '6cm'
    frequency = 10_000 if band == '3cm'
    frequency = 24_000 if band == '1.25cm'
    frequency = 47_000 if band == '6mm'
    frequency = 75_500 if band == '4mm'
    frequency = 119_980 if band == '2.5mm'
    frequency = 142_000 if band == '2mm'
    frequency = 241_000 if band == '1mm'
    frequency
  end

  # convert the supplied frequency to a hema-style frequency-band
  def self.hema_band_from_frequency(frequency)
    band = ''
    if frequency
      band = '1.8MHz' if (frequency >= 1.8) && (frequency <= 2)
      band = '3.6MHz' if (frequency >= 3.5) && (frequency <= 4)
      band = '5MHz' if (frequency >= 5.351) && (frequency <= 5.367)
      band = '7MHz' if (frequency >= 7) && (frequency <= 7.3)
      band = '10MHz' if (frequency >= 10.1) && (frequency <= 10.15)
      band = '14MHz' if (frequency >= 14.0) && (frequency <= 14.35)
      band = '18MHz' if (frequency >= 18.068) && (frequency <= 18.168)
      band = '21MHz' if (frequency >= 21.0) && (frequency <= 21.45)
      band = '24MHz' if (frequency >= 24.89) && (frequency <= 24.99)
      band = '28MHz' if (frequency >= 28.0) && (frequency <= 29.7)
      band = '50MHz' if (frequency >= 50) && (frequency <= 54)
      band = '70MHz' if (frequency >= 70) && (frequency <= 71)
      band = '144MHz' if (frequency >= 144) && (frequency <= 148)
      band = '220MHz' if (frequency >= 222) && (frequency <= 225)
      band = '430MHz' if (frequency >= 420) && (frequency <= 450)
      band = '900MHz' if (frequency >= 902) && (frequency <= 928)
      band = '1.24GHz' if (frequency >= 1240) && (frequency <= 1300)
      band = '2.3GHz' if (frequency >= 2300) && (frequency <= 2450)
      band = '3.4GHz' if (frequency >= 3300) && (frequency <= 3500)
      band = '5.7GHz' if (frequency >= 5650) && (frequency <= 5925)
      band = '10GHz' if (frequency >= 10_000) && (frequency <= 10_500)
      band = '24GHz' if (frequency >= 24_000) && (frequency <= 24_250)
      band = '47GHz' if (frequency >= 47_000) && (frequency <= 47_200)
      band = '76GHz' if (frequency >= 75_500) && (frequency <= 81_000)
      band = '122GHz' if (frequency >= 119_980) && (frequency <= 120_020)
      band = '136GHz' if (frequency >= 142_000) && (frequency <= 149_000)
      band = '248GHz' if (frequency >= 241_000) && (frequency <= 250_000)
    end
    band
  end
end
