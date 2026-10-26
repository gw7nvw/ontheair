# frozen_string_literal: true

MAX_SPOT_CONSOLIDATION_TIME = 15
MAX_SPOT_LIFETIME = 60

# typed: false
class ExternalSpot < ApplicationRecord
  before_validation :before_save_actions
  validate :record_is_unique
  after_save :create_consolidated_spot


  def before_save_actions
     self.comments=self.comments[0..254] if self.comments
     self.mode = self.mode.upcase if self.mode
  end

  def create_consolidated_spot
    newspot = false
    if time.to_time > 1.day.ago
      round_freq = frequency.to_d.round(4).to_s
      base_call = activatorCallsign.gsub(/\/./, "") # remove single character suffix
      dups=ConsolidatedSpot.find_by_sql [ "select * from consolidated_spots where (updated_at > ? or ('#{code}' = ANY(code) and updated_at > ?)) and \"activatorCallsign\" = '#{base_call}' and (frequency = '#{round_freq}' or frequency is null or frequency = '' or frequency = '0.0' or '#{round_freq}' = '' or '#{round_freq}' = '0.0') and (mode = '#{mode}' or mode is null or mode = '' or '#{mode}'='') order by created_at desc limit 1",  MAX_SPOT_CONSOLIDATION_TIME.minutes.ago, MAX_SPOT_LIFETIME.minutes.ago ]

      reuse = false
      if dups and dups.count>0
        logger.error("SPOTCHECK: DUPS")
        # check for exact matches within that result set
        fulldups=ConsolidatedSpot.find_by_sql [ "select * from consolidated_spots where id in (?) and code @> ARRAY[?::varchar] and code <@ ARRAY[?::varchar]", dups.pluck(:id), code, code ]
        if fulldups and fulldups.count>0 # prioritise full duplicate
          dups = fulldups
          reuse = true
        else
          reuse = true
          # check that new assets overlap with old (VK/ZL)
          if code.match?(/VK|ZL|AU|NZ/)
            logger.error("SPOTCHECK: NZ/AU")
            if !Asset.overlap_all?(dups.first.code, [ code ])
              logger.error("SPOTCHECK: No everlap")
              reuse = false
            end
          end

          # check that n-fers are all programmes that allow n-fers
          if reuse == true
            dup = dups.first
            combined_codes = (dup.code + [ code ]).uniq
            combined_classes = Asset.get_pnp_classes_from_codes(combined_codes)
            logger.error("SPOTCHECK: #{combined_classes.to_json}")
            repeated_classes = combined_classes.tally.select { |item, count| count > 1 }.keys
            logger.error("SPOTCHECK: #{repeated_classes.to_json}")
            reuse = false if !AssetType.all_allow_multi?(repeated_classes)
          end
        end
      end

      # reuse existing spot if allowed, otherwise create new spot
      if reuse == true
        cs=dups.first
      else
        newspot = true
        cs=ConsolidatedSpot.new
        cs.activatorCallsign = base_call
        cs.frequency = round_freq
        cs.points = points if points and points>"0"
        cs.altM = altM if altM and altM>"0"
        cs.mode = mode
      end
      cs.frequency = round_freq if round_freq and round_freq != "" and round_freq.to_d != 0
      cs.mode = mode if mode and mode != ""
      cs.time += [ time ]
      cs.callsign += [ callsign ]
      if !cs.code.include?(code)
        cs.code += [ code ]
        cs.name += [ (name||"") ]
        cs.spot_type += [ spot_type ]
      end
      cs.comments += [ "["+(spot_type||"")+"] "+((callsign||"")+": "+(comments||"") + " ("+(time.strftime("%H:%M:%S")||"")+")")]
      cs.comments = cs.comments.slice(0, 255)
      cs.save
    end
  end

  def record_is_unique
    dup = ExternalSpot.where(
      time: self.time,
      activatorCallsign: self.activatorCallsign
    ).exists?
    full_dup = ExternalSpot.where(attributes.except("id", "created_at", "updated_at", "epoch")).exists? if dup
    errors.add(:id, "Record is duplicate") if full_dup
  end

  def self.delete_old_spots
    oneweekago=Time.at(Time.now.to_i - 60 * 60 * 24 * 7).in_time_zone("UTC").to_s
    ActiveRecord::Base.connection.execute("delete from external_spots where time < '#{oneweekago}'")
  end

  def self.fetch
    all_spots = []

    # 1. Guard against over-frequent calls
    thirtysecondsago = Time.at(Time.now.to_i - 30).in_time_zone("UTC").to_s
    as = AdminSettings.first
    return if as.last_spot_read && (as.last_spot_read > thirtysecondsago)

    as.update_column(:last_spot_read, Time.now.utc)

    # 2. clear old spots > 1 week ago from DB
    ExternalSpot.delete_old_spots
    ConsolidatedSpot.delete_old_spots

    # 3. Fetch all spots
    spots = fetch_sota
    all_spots.concat(normalize_sota_spots(spots))

    spots = fetch_sota
    all_spots.concat(normalize_pota_spots(spots))

    spots = fetch_llota
    all_spots.concat(normalize_llota_spots(spots))

    spots = fetch_wwff
    all_spots.concat(normalize_wwff_spots(spots))

    spots = fetch_hema
    all_spots.concat(normalize_hema_spots(spots_string))

    # 4. Guard against empty runs (e.g. if all APIs time out)
    return if all_spots.empty?

    # 5. Fire ONE single high-speed bulk transaction into PostgreSQL
    # We return both the raw IDs and the updated_at timestamp to identify state shifts.
    db_result = ExternalSpot.upsert_all(
      all_spots,
      unique_by: [:source_api, :source_id],
      returning: [:id, :consolidated_spots_key, :updated_at, :created_at]
    )

    # 6. Filter for only the external records that actually CHANGED or were NEW 
    # during this minute's sweep (ignoring pristine un-changed duplicates)
    changed_external_rows = db_result.select do |row|
      row['updated_at'] >= 1.minute.ago
    end

    # If there are changes, consolidate them into consolidated_spots
    if changed_external_rows.any?
     consolidate_changed_spots(changed_external_rows)
    end
  end

  private

  def normalize_hema_spots(raw_text_stream)
  # 1. Split rows by '=', ignoring the header/timestamp line if it doesn't contain a spot
  rows = raw_text_stream.to_s.split('=')

  # Remove the very first element if it's just the top-level timestamp (e.g., "26/10/2026 05:47")
  rows.shift if rows.first&.include?('/') && !rows.first&.include?(';')

  rows.map do |row|
    columns = row.split(';')
    next if columns.size < 6 # Skip malformed or trailing empty splits

    # Safe extraction based on the positions we mapped out
    hema_id   = columns[1]&.strip
    activator = columns[2]&.strip&.upcase
    code      = columns[3]&.strip&.upcase
    name      = columns[4]&.strip

    # Parse "7.085 (SSB)" into components
    freq_mode_raw = columns[5]&.strip || ""
    frequency     = freq_mode_raw.split(' ').first # "7.085"
    mode          = freq_mode_raw.match(/\((.*?)\)/)&.captures&.first&.upcase # "SSB"

    # Parse spotter out of "(HEMA_ASSISTANT) comment here"
    spotter_comment_raw = columns[6]&.strip || ""
    spotter = spotter_comment_raw.match(/\((.*?)\)/)&.captures&.first&.upcase || activator
    comment = spotter_comment_raw.gsub(/\(.*?\)/, '').strip.slice(0, 255)

    {
      source_api:        "HEMA",
      source_id:         hema_id, # "6261" - Clean and verified!
      time:              columns[0] ? Time.zone.parse(columns[0]).utc : Time.now.utc,
      callsign:          spotter,
      activatorCallsign: activator,
      code:              code,
      name:              name,
      frequency:         frequency,
      mode:              mode,
      comments:          comment,
      spot_type:         "HEMA",
      created_at:        Time.now.utc,
      updated_at:        Time.now.utc
    }
  end.compact
end

def normalize_llota_spots(raw_spots)
  raw_spots.map do |spot|
    latest_history = spot["history"]&.last || {}

    {
      # The 2-field matching anchors
      source_api:        "LLOTA",
      source_id:         spot["id"].to_s, # Ensure the API's unique ID is mapped here

      time:              spot["updated_at"] ? Time.zone.parse(spot["updated_at"]).utc : Time.now.utc,
      callsign:          latest_history["spotter_callsign"]&.strip&.upcase || spot["callsign"]&.strip&.upcase,
      activatorCallsign: spot["callsign"]&.strip&.upcase,
      code:              spot["reference"]&.strip&.upcase,
      name:              spot["reference_name"]&.strip,
      frequency:         spot["frequency"].present? ? (spot["frequency"].to_f / 1000.0).to_s : nil,
      mode:              spot["mode"]&.strip&.upcase,
      comments:          latest_history["comment"]&.to_s&.slice(0, 255),
      spot_type:         "LLOTA",
      created_at:        Time.now.utc,
      updated_at:        Time.now.utc
    }
  end
end

def normalize_wwff_spots(raw_spots)
  raw_spots.map do |spot|
    {
      # The 2-field matching anchors
      source_api:        "wWFF",
      source_id:         spot["id"].to_s, # Ensure the API's unique ID is mapped here

      time:              spot["spot_time_formatted"] ? Time.zone.parse(spot["spot_time_formatted"]).utc : Time.now.utc,
      callsign:          spot["callsign"]&.strip&.upcase,
      activatorCallsign: spot["activator"]&.strip&.upcase,
      code:              spot["reference"]&.strip&.upcase,
      name:              spot["reference_name"]&.strip,
      frequency:         spot["frequency_khz"].present? ? (spot["frequency_khz"].to_f / 1000.0).to_s : nil,
      mode:              spot["mode"]&.strip&.upcase,
      comments:          spot["remarks"]&.to_s&.slice(0, 255),
      spot_type:         "WWFF",
      created_at:        Time.now.utc,
      updated_at:        Time.now.utc
    }
  end
end

def normalize_pota_spots(raw_spots)
  raw_spots.map do |spot|
    {
      # The 2-field matching anchors
      source_api:        "POTA",
      source_id:         spot["spotId"].to_s, # Ensure the API's unique ID is mapped here

      time:              spot["spotTime"] ? Time.zone.parse(spot["spotTime"]).utc : Time.now.utc,
      callsign:          spot["spotter"]&.strip&.upcase,
      activatorCallsign: spot["activator"]&.strip&.upcase,
      code:              spot["reference"]&.strip&.upcase,
      name:              spot["name"]&.strip,
      frequency:         spot["frequency_khz"].present? ? (spot["frequency_khz"].to_f / 1000.0).to_s : nil,
      mode:              spot["mode"]&.strip&.upcase,
      comments:          spot["comments"]&.to_s&.slice(0, 255),
      spot_type:         "POTA",
      created_at:        Time.now.utc,
      updated_at:        Time.now.utc
    }
  end
end

def normalize_sota_spots(raw_spots)
  raw_spots.map do |spot|
    {
      # The 2-field matching anchors
      source_api:        "SOTA",
      source_id:         spot["id"].to_s, # Ensure the API's unique ID is mapped here

      time:              spot["timeStamp"] ? Time.zone.parse(spot["spotTime"]).utc : Time.now.utc,
      callsign:          spot["callsign"]&.strip&.upcase,
      activatorCallsign: spot["activatorCallign"]&.strip&.upcase,
      code:              spot["summitCode"]&.strip&.upcase,
      name:              spot["summitName"]&.strip,
      frequency:         spot["frequency"]&.strip,
      mode:              spot["mode"]&.strip&.upcase,
      comments:          spot["comments"]&.to_s&.slice(0, 255),
      spot_type:         "SOTA",
      created_at:        Time.now.utc,
      updated_at:        Time.now.utc
    }
  end
end

def fetch_sota
  spots=[]
  # Check 'epoch' latest spot update key
  epoch_url = "https://api-db2.sota.org.uk/api/spots/epoch"
  as=AdminSettings.first
  old_epoch=as.sota_epoch
  new_epoch = fetch_external_url(epoch_url)

  # if epoch has chnaged, get new spots
  unless old_epoch==new_epoch
    as.sota_epoch=new_epoch
    as.save

    begin
      Timeout.timeout(10) do
        # read new spots
        url = "https://api-db2.sota.org.uk/api/spots/50/all/all"
        raw_response = fetch_external_url(url)
        spots = JSON.parse(raw_response.blank? ? "[]" : raw_response)
        # puts "GOT SOTA: "+spots.to_json
      end
    rescue
      puts "ERROR: SOTA Timeout"
    else
    end
  end
  spots
end

def fetch_pota
  # POTA
  spots=[]
  begin
    Timeout.timeout(10) do
      url = "https://api.pota.app/spot/activator"
      raw_response = fetch_external_url(url)
      spots = JSON.parse(raw_response.blank? ? "[]" : raw_response)
      # puts "GOT POTA: "+spots.to_json
    end
  rescue
    puts "ERROR: POTA Timeout"
  else
  end
end

def fetch_wwff
  # WWFF
  spots=[]
  begin
    Timeout.timeout(30) do
      url = "https://spots.wwff.co/static/spots.json"
      raw_response = fetch_external_url(url)
      spots = JSON.parse(raw_response.blank? ? "[]" : raw_response)
      # puts "GOT WWFF: "+spots.to_json
    end
  rescue
    puts "ERROR: WWFF Timeout"
  else
  end
  spots
end

def fetch_llota
  # LLOTA
  spots=[]
  begin
    Timeout.timeout(30) do
      url = "https://llota.app/api/spots"
      raw_response = fetch_external_url(url)
      spots = JSON.parse(raw_response.blank? ? "[]" : raw_response)
      # puts "GOT LLOTA: "+spots.to_json
    end
  rescue
    puts "ERROR: LLOTA Timeout"
  else
  end
  spots
end

def fetch_hema
  # HEMA
  hemaspots = []
  begin
    Timeout.timeout(30) do
      url = "http://hema.org.uk/spotsMobile.jsp"
      spots_string = fetch_external_url(url)
    end
  rescue
    puts "ERROR: HEMA Timeout"
  else
  end
  spots_string
end

def consolidate_changed_spots(changed_external_rows)
  external_spot_ids = changed_external_rows.map { |row| row['id'] }
  spots_to_process  = ExternalSpot.where(id: external_spot_ids).to_a

  spots_to_process.each do |external_spot|
    # Step 1: Clean data and query candidate target
    round_freq = external_spot.frequency.to_d.round(4).to_s
    base_call  = external_spot.activatorCallsign.gsub(/\/./, "")

    # Step 2: Check if we can merge into existing spot
    matching_spot = find_matching_consolidated_spot(external_spot)

    merge = true if matching_spot and consolidation_valid?(external_spot, matching_spot)

    if merge == true
      cs = matching_spot
    else
      cs = ConsolidatedSpot.new(
        activatorCallsign: base_call,
        frequency:         round_freq,
        mode:              external_spot.mode
      )
      cs.points = external_spot.points if external_spot.points.present? && external_spot.points.to_i > 0
      cs.altM   = external_spot.altM   if external_spot.altM.present? && external_spot.altM.to_i > 0
    end
    # 4. Safe Attribute Overlay
    cs.frequency = round_freq if round_freq.present? && round_freq.to_d != 0
    cs.mode      = external_spot.mode if external_spot.mode.present?
    cs.time += [ external_spot.time ]
    cs.callsign += [ external_spot.callsign ]
    if !cs.code.include?(external_spot.code)
      cs.code += [ external_spot.code ]
      cs.name += [ (external_spot.name||"") ]
      cs.spot_type += [ external_spot.spot_type ]
    end
    formatted_comment = "["+(external_spot.spot_type||"")+"] "+((external_spot.callsign||"")+": "+(external_spot.comments||"") + " ("+(external_spot.time.strftime("%H:%M:%S")||"")+")")
    cs.comments = cs.comments + [formatted_comment.slice(0, 255)]
    
    # 7. Persist and hand off to Step 3 Notifications Ledger
    if cs.changed?
      is_new_record = cs.new_record?
      cs.save!

      # Triggers the lightning-fast GIN index tracking ledger query we wrote earlier
      process_step_3_notifications(cs, is_new: is_new_record)
    end
  end
end

def consolidation_valid?(external_spot, consolidated_spot)
  #allow if code alrady there
  return true if consolidated_spot.code.include?(external_spot.code)


  # check that new assets overlap with old (VK/ZL)
  if external_spot.code.match?(/VK|ZL|AU|NZ/)
    logger.debug("SPOTCHECK: NZ/AU")
    if !Asset.overlap_all?(dups.first.code, [ code ])
      logger.debug("SPOTCHECK: No overlap")
      return false
    end
  end

  # check that n-fers are all programmes that allow n-fers
  combined_codes = (consolidated_spot.code + [ external_spot.code ]).uniq
  combined_classes = Asset.get_pnp_classes_from_codes(combined_codes)
  logger.debug("SPOTCHECK: #{combined_classes.to_json}")
  repeated_classes = combined_classes.tally.select { |item, count| count > 1 }.keys
  logger.error("SPOTCHECK: #{repeated_classes.to_json}")
  return false if !AssetType.all_allow_multi?(repeated_classes)

  return true
end

def merge_external_data!(external_spot, consolidated_spot)

end


def find_matching_consolidated_spot(external_spot)
  # 1. Clean the incoming matching variables exactly as your logic dictates
  round_freq = external_spot.frequency.to_d.round(4).to_s
  base_call  = external_spot.activatorCallsign.gsub(/\/./, "") # Remove single character suffix

  # 2. Build a clean, parameterized ActiveRecord relation
  ConsolidatedSpot.where(activatorCallsign: base_call)
    .where(
      "(updated_at > :max_consolidation) OR (:code = ANY(code) AND updated_at > :max_lifetime)",
      max_consolidation: MAX_SPOT_CONSOLIDATION_TIME.minutes.ago,
      max_lifetime:      MAX_SPOT_LIFETIME.minutes.ago,
      code:              external_spot.code
    )
    .where(
      "frequency = :freq OR frequency IS NULL OR frequency = '' OR frequency = '0.0' OR :freq = '' OR :freq = '0.0'",
      freq: round_freq
    )
    .where(
      "mode = :mode OR mode IS NULL OR mode = '' OR :mode = ''",
      mode: external_spot.mode
    )
    .order(created_at: :desc)
    .first
end
end
