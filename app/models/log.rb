# frozen_string_literal: true

# typed: false
class Log < ActiveRecord::Base
  validates :callsign1,  presence: true, length: { maximum: 50 }

  belongs_to :createdBy, class_name: 'User'
  before_save { before_save_actions }
  after_save { update_contacts }

  def before_save_actions
    remove_call_suffix
    self.callsign1 = UserCallsign.clean(callsign1)
    add_user_ids
    check_codes_in_location
    location = get_most_accurate_location
    add_containing_codes(location[:asset])
    update_classes
  end

  #################################
  # CALCULATED PARAMETERS
  #################################

  def user
    User.find(user1_id)
  end

  def assets
    asset_codes ? Asset.where(code: asset_codes) : []
  end

  def asset_names
    asset_names = assets.map(&:name)
    asset_names ||= ''
    asset_names
  end

  def asset_code_names
    if asset_codes
      asset_names = asset_codes.map do |ac|
        asset = Asset.assets_from_code(ac).first
        asset ? '[' + asset[:code] + '] ' + asset[:name] : ''
      end
    end
    asset_names ||= []
    asset_names
  end

  def contacts
    cs = Contact.where(log_id: id) if id && id.positive?
    cs
  end

  # uses contact time by preference as log date will be fore 00:00UTC which may be
  # in a different local day
  def localdate(currentuser)
    t = nil
    tz = currentuser ? Timezone.find_by_id(currentuser.timezone) : Timezone.find_by(name: 'UTC')
    cs = Contact.find_by_sql [' select * from contacts where log_id =' + id.to_s + ' order by time desc limit 1 ']
    c1 = cs.first
    if c1 && c1.time
      thetime = c1.time
      t = thetime.in_time_zone(tz.name).strftime('%Y-%m-%d')
    elsif date
      t = date.strftime('%Y-%m-%d')
    else
      t = ''
    end
    t
  end

  #################################
  # BEFORE SAVE ACTIONS
  #################################
  def add_user_ids
    # look up callsign1 at contact.time
    user1 = User.find_by_callsign_date(callsign1, date, true)
    self.user1_id = user1.id if user1
  end

  def remove_call_suffix
    self.callsign1 = User.remove_call_suffix(callsign1) if callsign1['/']
  end

  # update asset_classes array to show asset type for all asset_codes - in order
  def update_classes
    asset_classes = []
    asset_codes.each do |code|
      asset = Asset.assets_from_code(code)
      asset_classes.push(asset.first[:type]) if asset && asset.count.positive?
    end
    self.asset_classes = asset_classes
  end

  def check_codes_in_location
    if asset_codes.nil? || (asset_codes == []) || (asset_codes == [''])
      self.asset_codes = Asset.check_codes_in_text(loc_desc1)
    end
    if asset_codes.nil? || (asset_codes == []) || (asset_codes == [''])
      self.asset_codes = Asset.check_codes_in_text(comments1)
    end
  end

  def get_most_accurate_location(force = false)
    location = { location: location1, source: loc_source, asset: nil }

    self.loc_source = nil if location1.nil?

    # for anything other than a user specified location
    if loc_source != 'user'
      # only overwrite a location when asked to
      if location1 && (force == true)
        self.loc_source = nil
        self.location1 = nil
      end

      # lookup location for asset by finding most accurate asset location
      location = Asset.get_most_accurate_location(asset_codes, loc_source)
      self.loc_source = location[:source]
      self.location1 = location[:location]
    end
    location
  end

  def add_containing_codes(asset)
    self.asset_codes = Asset.find_master_codes(asset_codes)
    self.asset_codes = get_all_asset_codes(asset) if !do_not_lookup == true
  end

  def get_all_asset_codes(asset)
    codes = asset_codes
    newcodes = codes
    # Add ZL child codes by lcoation
    if location1 then newcodes += Asset.containing_codes_from_location(location1, asset) end
    # Add VK child codes using lookup table
    codes.each do |code|
      newcodes += VkAsset.containing_codes_from_parent(code)
    end
    newcodes.uniq
  end

  def update_contacts
    contacts = Contact.where(log_id: id)
    contacts.each do |cle|
      cle.callsign1 = callsign1
      cle.date = date
      # pick up changes in date and apply to time
      cle.time = Time.iso8601(date.strftime('%Y-%m-%d') + 'T' + cle.time.strftime('%H:%M:%SZ'))
      cle.loc_desc1 = loc_desc1
      cle.is_qrp1 = is_qrp1
      cle.power1 = power1
      cle.is_portable1 = is_portable1
      cle.x1 = x1
      cle.y1 = y1
      cle.location1 = location1
      cle.asset1_codes = asset_codes
      cle.save
    end
  end

  ####################################################################
  # LOG FILE IMPORTS
  ####################################################################

  def self.import(filetype, currentuser, filestr, user, default_callsign = nil, default_location = nil, no_create = false, ignore_error = false, do_not_lookup = false, force_callsign = false)
    logs = []
    contacts = []
    errors = []
    contacts_per_log = []
    invalid_log = []

    log_count = 0
    contact_count = 0
    # check encoding
    unless filestr.valid_encoding?
      filestr = filestr.encode('UTF-16be', invalid: :replace, undef: :replace, replace: '?').encode('UTF-8')
      logger.info 'Invalid encoding repaired'
    end

    # force to ASCII. HAMRS seems to include broken UTF8 which above check fails to fix
    # TODO: need a better fix that doesn't lose extended characters.
    filestr = filestr.encode('ASCII', invalid: :replace, undef: :replace, replace: '?').encode('UTF-8')

    # extract array of contacts from the log as 'lines'
    lines = if filetype == 'adif'
              Log.prepare_adif(filestr)
            else
              filestr.lines
            end

    record_count = 0
    skip_count = 0
    lines.each do |line|
      contact = Contact.new
      protolog = Log.new

      # apply any default values speficied in the upload log screen
      protolog.do_not_lookup = do_not_lookup
      if user && default_callsign
        contact.callsign1 = default_callsign.encode('UTF-8')
        protolog.callsign1 = default_callsign.encode('UTF-8')
      end
      logid = nil
      contact.asset1_codes = []
      contact.asset2_codes = []
      if default_location && !default_location.empty? && !default_location.strip.empty?
        protolog.asset_codes.push(default_location.strip.upcase)
        contact.asset1_codes.push(default_location.strip.upcase)
      end

      contact.timezone = Timezone.find_by(name: 'UTC').id
      # if it is a valid contact it will have one of these two fields
      # ignore anything that doesn't
      next unless Log.valid_logfile_entry(line, filetype)

      # parse this record
      if filetype == 'adif'
        protolog, contact, timestring = Log.parse_adif_record(line, protolog, contact)
      else
        protolog, contact, timestring = Log.parse_csv_record(line, protolog, contact)
      end

      # Override callsign if asked
      if force_callsign
        contact.callsign1 = default_callsign
        protolog.callsign1 = default_callsign
      end

      record_count += 1
      # extract asset_codes from location field
      protolog.check_codes_in_location

      # check if this proto-log matches an existing log for this file
      lc = 0
      logs.each do |log|
        if (log.callsign1 == protolog.callsign1) && (log.date == protolog.date) && (protolog.asset_codes - log.asset_codes).empty?
          logid = lc
          logger.info "IMPORT: matched existing log: #{lc}"
        end
        lc += 1
      end

      # if not, create a new log from the proto-log
      if logid.nil?
        logger.info 'IMPORT: creating new log (' + log_count.to_s + ')'
        log_count = logs.count
        invalid_log[log_count] = true
        # lstr = protolog.to_json
        # logs[log_count]=Log.new(JSON.parse(lstr))
        logs[log_count] = Log.new(protolog.attributes)

        # check if user has permissions to create this log and if log is valid
        loguser = User.find_by_callsign_date(logs[log_count].callsign1, logs[log_count].date)
        if loguser && ((loguser.id == user.id) || currentuser.is_admin)
          if logs[log_count].valid?
            logger.info 'Valid log ' + log_count.to_s
            invalid_log[log_count] = false
          else
            errors.push("Record #{record_count}: Create log #{log_count} failed: " + logs[log_count].errors.messages.to_s)
          end
        else
          errors.push("Record #{record_count}: Create log #{log_count} failed: you cannot create a log for a callsign not registered to your account (#{user.callsign}) at the time of the contact (#{logs[log_count].callsign1} #{logs[log_count].date})")
        end

        contacts_per_log[log_count] = 0
        logid = log_count
        log_count += 1
      end

      # apply this contact to the log it belongs to
      contact.log_id = logid

      # create a new contact from the log entry data
      contact = Contact.new(contact.attributes)

      #puts contact.to_json
      # get time/date into correct format
      timestring = (timestring || '').rjust(4, '0')

      if timestring && protolog.date then contact.time = (protolog.date.strftime('%Y-%m-%d') + ' ' + timestring[0..1] + ':' + timestring[2..3]).to_time end
      # validate contact
      if !contact.date
        errors.push("Record #{record_count}: Save contact #{contact_count} failed: no date/time")
      elsif (!contact.asset1_codes || contact.asset1_codes.count.zero?) && (!contact.asset2_codes || contact.asset2_codes.count.zero?)
        errors.push("Record #{record_count}: Save contact #{contact_count} failed: no activation location for either party")
      else
        res = true
        create = false
        if no_create == true
          # only save if both calls are registered
          uc = UserCallsign.find_by(callsign: contact.callsign2)
          if uc
            res = contact.valid?
            create = true
          else
            skip_count += 1
            create = false
          end
        else
          # always save
          res = contact.valid?
          create = true
        end
        unless res
          logger.info 'IMPORT: save contact failed'
          errors.push("Record #{record_count}: Save contact #{contact_count} failed: " + contact.errors.messages.to_s)
        end
        if res && create
          contacts[contact_count] = contact
          contacts_per_log[contact.log_id] += 1
          contact_count += 1
        end
      end
      # end of parms.each
    end # end of lines.each

    good_logs = 0
    # create logs
    lc = 0
    logs.each do |_log|
      if contacts_per_log[lc].positive? && !invalid_log[lc]
        if errors.empty? || ignore_error
          logger.info logs[lc].callsign1.inspect
          logger.info logs[lc].callsign1.length
          logger.info 'SAVE: ' + logs[lc].to_json
          if logs[lc].save
            logs[lc].reload
            good_logs += 1
          else
            errors.push("FATAL: Save log #{lc} failed: " + logs[lc].errors.messages.to_s)
            invalid_log[lc] = true
          end
        else
          good_logs += 1
        end
      else
        logger.info 'Skipping empty log: ' + lc.to_s
      end
      lc += 1
    end

    # create contacts
    cc = 0
    good_contacts = 0
    contacts.each do |contact|
      if invalid_log[contact.log_id]
        logger.info "Skipping contact #{cc} as log #{contact.log_id} invalid"
      elsif errors.empty? || ignore_error
        contact.log_id = logs[contact.log_id].id
        if contact.save
          contact.reload
          #puts contact.to_json
          good_contacts += 1
        else
          errors.push("FATAL: Save contact #{cc} failed: " + contact.errors.messages.to_s)
        end
      else
        good_contacts += 1
      end
    end
    logger.info 'IMPORT: clean exit'
    logger.info errors
    logger.info logs.to_json
    { logs: logs.reject { |log| log.id.nil? }, errors: errors, success: true, good_logs: good_logs, good_contacts: good_contacts }
  end

  #####################################################################################
  # HELPERS
  #####################################################################################

  def update_qualified
    qualified = []
    asset_classes.each do |ac|
      at = AssetType.find_by(name: ac)
      unique_contacts = Contact.find_by_sql [" select distinct callsign2, mode, band from contacts where log_id=#{id};"]
      asset_qualified = if at && (unique_contacts.count >= at.min_qso)
                          true
                        else
                          false
                        end
      qualified.push(asset_qualified)
    end

    self.qualified = qualified
    update_column(:qualified, qualified)
  end

  def self.valid_logfile_entry(line, filetype)
    valid = if filetype == 'adif'
              line.upcase['CALL'] ? true : false
            else
              line[0..1] == 'V2'
            end
    valid
  end

  def self.prepare_adif(filestr)
    # Read ADIF
    # remove header
    logbody = if filestr['<EOH>'] || filestr['<eoh>']
                filestr.split(/<EOH>|<eoh>/)[1]
              else
                filestr
              end

    # check for <eor>
    lines = if logbody['<eor>'] || logbody['<EOR>']
              # each record terminated by <eor>
              logbody.split(/<EOR>|<eor>/)
            else
              # if no <eor> then assume one record per line
              logbody.lines
            end
    lines
  end

  def self.parse_csv_record(line, protolog, contact)
    timestr = nil
    # split by ','
    # TODO: need way of doing this that respects ',' in quotes (does not split quoted text)
    fields = line.split(',')

    # my calls
    value = fields[1]
    if value && !value.empty? && !value.strip.empty?
      callsign = value.strip.upcase
      # remove suffix
      callsign = User.remove_call_suffix(callsign) if callsign['/']
      protolog.callsign1 = callsign
      contact.callsign1 = callsign
    end

    # date
    value = fields[3]
    if value && !value.empty? && !value.strip.empty?
      parts = value.strip.split('/')
      if parts[0].length == 2 # assume dd-mm-yy as per iPnP
        protolog.date = if parts[2].length == 2 # assume dd-mm-yy as per iPnP
                          ('20' + parts[2] + '/' + parts[1] + '/' + parts[0]).to_date
                        else
                          (parts[2] + '/' + parts[1] + '/' + parts[0]).to_date
                        end
        contact.date = protolog.date
      else # assume yyyy-mm-dd as per SOTA
        protolog.date = value.strip.to_date
        contact.date = value.strip.to_date
      end
    end

    # my location
    value = fields[2]
    if value && !value.empty? && !value.strip.empty?
      values = value.split(';')
      values.each do |val|
        val = Asset.correct_separators(val.strip)
        protolog.asset_codes.push(val)
        contact.asset1_codes.push(val)
        protolog.is_portable1 = true
        contact.is_portable1 = true
      end
    end

    # time
    value = fields[4]
    if value && !value.empty? && !value.strip.empty?
      timestr = value.strip.delete(':')
    end

    # band
    value = fields[5]
    if value && !value.empty? && !value.strip.empty?
      contact.frequency = value.strip.gsub(/[GMk]Hz/, '')
    end

    # mode
    value = fields[6]
    contact.mode = value.strip if value && !value.empty? && !value.strip.empty?

    # other call
    value = fields[7]
    if value && !value.empty? && !value.strip.empty?
      callsign = value.strip.upcase
      # remove suffix
      callsign = User.remove_call_suffix(callsign) if callsign['/']
      contact.callsign2 = callsign
    end

    # other location
    value = fields[8]
    if value && !value.empty?
      values = value.split(';')
      values.each do |val|
        val = Asset.correct_separators(val.strip)
        contact.asset2_codes.push(val)
        contact.is_portable2 = true
      end
    end
    # comment
    value = fields[9]
    if value && !value.empty?
      contact.comments1 = value.strip # strip to not pick up and CRLF stuff from end of line
    end

    [protolog, contact, timestr]
  end

  def self.parse_adif_record(line, protolog, contact)
    timestr = nil
    freq_basis = ''
    my_city = ''
    my_state = ''
    my_country = ''
    city = ''
    state = ''
    country = ''
    callsign_source = nil

    line.split('<').each do |parm|
      next unless parm && !parm.empty?
      key = parm.split('>')[0]
      len = key.split(':')[1]
      key = key.split(':')[0]
      value = parm.split('>')[1]
      if value
        logger.info 'value: ' + value.to_s
        logger.info 'length: ' + value.length.to_s
        logger.info 'len: ' + len.to_s
        logger.info 'key: ' + key
      end

      if len && len.to_i.positive?
        logger.info 'Truncate'
        value = value[0..len.to_i - 1]
        logger.info 'length: ' + value.length.to_s
      end
      logger.info 'DEBUG: ' + key.downcase
      case key.downcase

      when 'station_callsign'
        if value && !value.empty? && !value.strip.empty?
          callsign = value.strip.upcase
          callsign_source = 1
          # remove suffix
          callsign = User.remove_call_suffix(callsign) if callsign['/']
          protolog.callsign1 = callsign
          contact.callsign1 = callsign
        end
      when 'operator'
        if value && !value.empty? && !value.strip.empty?
          if !callsign_source || (callsign_source > 2)
            callsign = value.strip.upcase
            # remove suffix
            callsign = User.remove_call_suffix(callsign) if callsign['/']
            protolog.callsign1 = callsign
            contact.callsign1 = callsign
            callsign_source = 2
          end
        end
      when 'owner_callsign'
        if value && !value.empty? && !value.strip.empty?
          if !callsign_source || (callsign_source > 3)
            callsign = value.strip.upcase
            # remove suffix
            callsign = User.remove_call_suffix(callsign) if callsign['/']
            protolog.callsign1 = callsign
            contact.callsign1 = callsign
            callsign_source = 3
          end
        end
      when 'eq_call'
        if value && !value.empty? && !value.strip.empty?
          if !callsign_source || (callsign_source > 4)
            callsign = value.strip.upcase
            # remove suffix
            callsign = User.remove_call_suffix(callsign) if callsign['/']
            protolog.callsign1 = callsign
            contact.callsign1 = callsign
            callsign_source = 4
          end
        end
      when 'qso_date'
        if value && !value.empty? && !value.strip.empty?
          protolog.date = value.strip.to_date
          contact.date = value.strip.to_date
        end
      when 'qso_date_off'
        if value && !value.empty? && !value.strip.empty? && !contact.date
          protolog.date = value.strip.to_date
          contact.date = value.strip.to_date
        end
      when 'my_altitude'
        if value && !value.empty? && !value.strip.empty?
          contact.altitude1 = value.strip.to_i
        end
      when 'my_pota_ref'
        if value && !value.empty? && !value.strip.empty?
          values = value.split(',')
          values.each do |val|
            val = Asset.correct_separators(val.strip)
            protolog.asset_codes.push(val)
            contact.asset1_codes.push(val)
            protolog.is_portable1 = true
            contact.is_portable1 = true
          end
        end
      when 'my_wwff_ref'
        if value && !value.empty? && !value.strip.empty?
          values = value.split(',')
          values.each do |val|
            val = Asset.correct_separators(val.strip)
            protolog.asset_codes.push(val)
            contact.asset1_codes.push(val)
            protolog.is_portable1 = true
            contact.is_portable1 = true
          end
        end
      when 'my_sota_ref'
        if value && !value.empty? && !value.strip.empty?
          values = value.split(',')
          values.each do |val|
            val = Asset.correct_separators(val.strip)
            protolog.asset_codes.push(val)
            contact.asset1_codes.push(val)
            protolog.is_portable1 = true
            contact.is_portable1 = true
          end
        end
      when 'my_sig_info'
        if value && !value.empty? && !value.strip.empty?
          values = value.split(',')
          values.each do |val|
            val = Asset.correct_separators(val.strip)
            protolog.asset_codes.push(val)
            contact.asset1_codes.push(val)
            protolog.is_portable1 = true
            contact.is_portable1 = true
          end
        end
      when 'comment'
        if value && !value.empty?
          contact.comments1 = value.delete("\r").delete("\n").strip
        end
      when 'notes'
        if value && !value.empty?
          contact.comments2 = value.delete("\r").delete("\n").strip
        end
      when 'my_antenna'
        if value && !value.empty?
          protolog.antenna1 = value.delete("\r").delete("\n")
          contact.antenna1 = value.delete("\r").delete("\n")
        end
      when 'my_rig'
        if value && !value.empty?
          protolog.transceiver1 = value.delete("\r").delete("\n").strip
          contact.transceiver1 = value.delete("\r").delete("\n").strip
        end
      when 'my_lat'
        if value && !value.empty?
          pos = Log.degs_from_deg_min_sec(value)
          contact.y1 = pos
          protolog.y1 = pos
        end
      when 'my_lon'
        if value && !value.empty?
          pos = Log.degs_from_deg_min_sec(value)
          contact.x1 = pos
          protolog.x1 = pos
        end
      when 'my_gridsquare'
        if value && !value.empty? && !value.strip.empty?
          pos = Asset.maidenhead_to_lat_lon(value.strip)
          contact.location1 = "POINT(#{pos[:x]} #{pos[:y]})"
          protolog.location1 = "POINT(#{pos[:x]} #{pos[:y]})"
          protolog.loc_source = 'user'
        end
      when 'my_city'
        my_city = value.strip if value && !value.empty? && !value.strip.empty?
      when 'my_state'
        my_state = value.strip if value && !value.empty? && !value.strip.empty?
      when 'my_country'
        if value && !value.empty? && !value.strip.empty?
          my_country = value.strip
        end
      when 'tx_pwr'
        if value && !value.empty? && !value.strip.empty?
          contact.power1 = value.strip
          protolog.power1 = value.strip
          if value.strip.to_f <= 10
            contact.is_qrp1 = true
            protolog.is_qrp1 = true
          end
        end
      when 'band'
        if value && !value.empty? && !value.strip.empty?
          if freq_basis != 'freq' # freq priority over band
            contact.frequency = Contact.frequency_from_band(value.strip)
            freq_basis = 'band'
          end
        end
      when 'freq'
        if value && !value.empty? && !value.strip.empty?
          contact.frequency = value.strip
          freq_basis = 'freq'
        end
      when 'rst_sent'
        if value && !value.empty? && !value.strip.empty?
          contact.signal2 = value.strip
        end
      when 'rst_rcvd'
        if value && !value.empty? && !value.strip.empty?
          contact.signal1 = value.strip
        end
      when 'time_on'
        if value && !value.empty? && !value.strip.empty?
          timestr = value.strip.delete(':')
        end
      when 'time_off'
        if value && !value.empty? && !value.strip.empty?
          timestr = value.strip.delete(':') if !timestr || (timestr == '')
        end
      when 'altitude'
        if value && !value.empty? && !value.strip.empty?
          contact.altitude2 = value.strip.to_i
        end
      when 'lat'
        if value && !value.empty?
          pos = Log.degs_from_deg_min_sec(value)
          contact.y2 = pos
        end
      when 'lon'
        if value && !value.empty?
          pos = Log.degs_from_deg_min_sec(value)
          contact.x2 = pos
        end
      when 'gridsquare'
        if value && !value.empty? && !value.strip.empty?
          pos = Asset.maidenhead_to_lat_lon(value.strip)
          contact.location2 = "POINT(#{pos[:x]} #{pos[:y]})"
          contact.loc_source2 = 'user'
        end
      when 'mode'
        if value && !value.empty? && !value.strip.empty?
          contact.mode = value.strip
        end
      when 'submode'
        if value && !value.empty? && !value.strip.empty?
          contact.mode = value.strip
        end
      when 'rig'
        if value && !value.empty?
          contact.transceiver2 = value.delete("\r").delete("\n").strip
        end
      when 'name'
        if value && !value.empty? && !value.strip.empty?
          contact.name2 = value.strip
        end
      when 'call'
        if value && !value.empty? && !value.strip.empty?
          callsign = value.strip.upcase
          # remove suffix
          callsign = User.remove_call_suffix(callsign) if callsign['/']
          contact.callsign2 = callsign
        end
      when 'city'
        city = value.strip if value && !value.empty? && !value.strip.empty?
      when 'state'
        state = value.strip if value && !value.empty? && !value.strip.empty?
      when 'country'
        country = value.strip if value && !value.empty? && !value.strip.empty?
      when 'qth'
        city = value.strip if value && !value.empty? && !value.strip.empty?
      when 'rx_pwr'
        if value && !value.empty? && !value.strip.empty?
          contact.power2 = value.strip
          contact.is_qrp2 = true if value.strip.to_f <= 10
        end
      when 'pota_ref'
        if value && !value.empty?
          values = value.split(',')
          values.each do |val|
            val = Asset.correct_separators(val.strip)
            contact.asset2_codes.push(val)
            contact.is_portable2 = true
          end
        end
      when 'wwff_ref'
        if value && !value.empty?
          values = value.split(',')
          values.each do |val|
            val = Asset.correct_separators(val.strip)
            contact.asset2_codes.push(val)
            contact.is_portable2 = true
          end
        end
      when 'sota_ref'
        if value && !value.empty?
          values = value.split(',')
          values.each do |val|
            val = Asset.correct_separators(val.strip)
            contact.asset2_codes.push(val)
            contact.is_portable2 = true
          end
        end
      when 'sig_info'
        if value && !value.empty?
          values = value.split(',')
          values.each do |val|
            val = Asset.correct_separators(val.strip)
            contact.asset2_codes.push(val)
            contact.is_portable2 = true
          end
        end
      end
      # end of if
    end

    # combined fields
    contact.loc_desc2 = [city, state, country].compact.split('').flatten.join(', ')
    contact.loc_desc1 = [my_city, my_state, my_country].compact.split('').flatten.join(', ')
    protolog.loc_desc1 = [my_city, my_state, my_country].compact.split('').flatten.join(', ')

    if contact.x1 && contact.y1
      contact.location1 = "POINT(#{contact.x1} #{contact.y1})"
      protolog.location1 = "POINT(#{contact.x1} #{contact.y1})"
      protolog.loc_source = 'user'
    end
    if contact.x2 && contact.y2
      contact.location2 = "POINT(#{contact.x2} #{contact.y2})"
      contact.loc_source2 = 'user'
    end

    [protolog, contact, timestr]
  end

  # Convert [NSWE]<deg> <min> <sec.##> to +/-<deg.##>
  def self.degs_from_deg_min_sec(value)
    negative = false
    value = value.delete("\r").delete("\n")
    if value[0].casecmp('S').zero? || value[0].casecmp('W').zero?
      negative = true
      value = value[1..-1]
    end
    if value[0].casecmp('N').zero? || value[0].casecmp('E').zero?
      value = value[1..-1]
    end
    if value =~ /^\d{1,3} \d{1,3} \d{1}./
      deg = value.split(' ')[0]
      min = value.split(' ')[1]
      sec = value.split(' ')[2]
      pos = deg.to_f + (min.to_f / 60) + sec.to_f / 3600
    elsif value =~ /^\d{1,3} \d{1,3}\../
      deg = value.split(' ')[0]
      min = value.split(' ')[1]
      pos = deg.to_f + (min.to_f / 60)
    else
      pos = value.to_f
    end
    pos = -pos if negative

    pos
  end

  # one-off to apply clsses to all logs
  def self.update_all_classes
    logs = Log.all
    logs.each do |log|
      puts log.id
      log.update_classes
      log.update_column(:asset_classes, log.asset_classes)
    end
  end

  # one-off to add qualifed to all logs
  def self.update_qualified
    logs = Log.all
    logs.each do |log|
      puts log.id
      log.update_qualified
      # log.update_column(:qualifed, log.qualifed)
    end
  end
end
