# frozen_string_literal: true

MAX_SPOT_CONSOLIDATION_TIME = 15
MAX_SPOT_LIFETIME = 60

# typed: false
class ExternalSpot < ApplicationRecord
  before_validation :before_save_actions
  validate :record_is_unique
  after_save :after_save_actions

  # Define the absolute, uniform structure required for your bulk upserts
  UPSERT_BLUEPRINT = {
    source_api:        nil,
    source_id:         nil,
    time:              nil,
    callsign:          nil,
    activatorCallsign: nil,
    code:              nil,
    name:              nil,
    frequency:         nil,
    mode:              nil,
    comments:          nil,
    points:            nil,
    altM:              nil,
    is_test:           nil,
    spot_type:         nil,
    created_at:        nil,
    updated_at:        nil
  }.freeze


  def after_save_actions
    consolidate_changed_spots([self])
  end


  def before_save_actions
     self.comments=self.comments[0..254] if self.comments
     self.mode = self.mode.upcase if self.mode
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

    spots = fetch_pota
    all_spots.concat(normalize_pota_spots(spots))

    spots = fetch_llota
    all_spots.concat(normalize_llota_spots(spots))

    spots = fetch_wwff
    all_spots.concat(normalize_wwff_spots(spots))

    spots_string = fetch_hema
    all_spots.concat(normalize_hema_spots(spots_string))

    # 4. Guard against empty runs (e.g. if all APIs time out)
    return if all_spots.empty?
  
    deduplicated_payload = all_spots.index_by { |row| 
      "#{row[:source_api]}|#{row[:source_id]}" 
    }.values

    # 5. Fire ONE single high-speed bulk transaction into PostgreSQL
    # We return both the raw IDs and the updated_at timestamp to identify state shifts.
    logger.info all_spots.to_json
    db_result = ExternalSpot.upsert_all(
      deduplicated_payload,
      unique_by: [:source_api, :source_id],
      returning: [:id, :updated_at]
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
    comment = spotter_comment_raw&.to_s&.gsub(/\(.*?\)/, '')&.scrub&.strip&.slice(0, 255)

    spotstr = [
      callsign:          spotter,
      activatorCallsign: activator,
      code:              code,
      name:              name,
      frequency:         frequency,
      mode:              mode,
      comments:          comment,
    ].join('|')

    stable_hema_id = Digest::SHA256.hexdigest(spotstr)

    {
      source_api:        "HEMA",
      source_id:         stable_hema_id,
      callsign:          spotter,
      activatorCallsign: activator,
      code:              code,
      name:              name,
      frequency:         frequency.to_s,
      mode:              mode,
      comments:          comment,
      points:            nil,
      altM:              nil,
      time:              columns[0] ? Time.zone.parse(columns[0]).utc : Time.now.utc,
      is_test:           nil,
      spot_type:         "HEMA",
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
      comments:          latest_history["comment"]&.to_s&.scrub&.slice(0, 255),
      points:            nil,
      altM:              nil,
      is_test:           nil,
      spot_type:         "LLOTA",
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
      callsign:          spot["spotter"]&.strip&.upcase,
      activatorCallsign: spot["activator"]&.strip&.upcase,
      code:              spot["reference"]&.strip&.upcase,
      name:              spot["reference_name"]&.strip,
      frequency:         spot["frequency_khz"].present? ? (spot["frequency_khz"].to_f / 1000.0).to_s : nil,
      mode:              spot["mode"]&.strip&.upcase,
      comments:          spot["remarks"]&.to_s&.scrub&.slice(0, 255),
      points:            nil,
      altM:              nil,
      is_test:           nil,
      spot_type:         "WWFF",
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
      frequency:         spot["frequency"].present? ? (spot["frequency"].to_f / 1000.0).to_s : nil,
      mode:              spot["mode"]&.strip&.upcase,
      comments:          spot["comments"]&.to_s&.scrub&.slice(0, 255),
      points:            nil,
      altM:              nil,
      is_test:           nil,
      spot_type:         "POTA",
    }
  end
end

def normalize_sota_spots(raw_spots)
  raw_spots.map do |spot|
    {
      # The 2-field matching anchors
      source_api:        "SOTA",
      source_id:         spot["id"].to_s, # Ensure the API's unique ID is mapped here

      time:              spot["timeStamp"] ? Time.zone.parse(spot["timeStamp"]).utc : Time.now.utc,
      callsign:          spot["callsign"]&.strip&.upcase,
      activatorCallsign: spot["activatorCallsign"]&.strip&.upcase,
      code:              spot["summitCode"]&.strip&.upcase,
      name:              spot["summitName"]&.strip,
      frequency:         spot["frequency"]&.to_s,
      mode:              (if spot['type']=='QRT' then 'QRT' else spot['mode']&.strip&.upcase end),
      comments:          spot["comments"]&.to_s&.scrub&.slice(0, 255),
      points:            spot["points"]&.to_s,
      altM:              spot["AltM"]&.to_s,
      is_test:           (spot['type']=='TEST'),
      spot_type:         "SOTA",
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
  spots
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
  spots_string=""
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
    base_call  = User.remove_call_suffix(external_spot.activatorCallsign||"UNKNOWN")

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
    cs.is_portable = true if external_spot.activatorCallsign.upcase.match(/\/P$/)
    cs.is_qrp = true if external_spot.activatorCallsign.upcase.match(/\/QRP$/)
    cs.is_mobile = true if external_spot.activatorCallsign.upcase.match(/\/M$/)
    if !cs.code.include?(external_spot.code)
      cs.code += [ external_spot.code ]
      cs.name += [ (external_spot.name||"") ]
      cs.spot_type += [ external_spot.spot_type ]
    end
    formatted_comment = "["+(external_spot.spot_type||"")+"] "+((external_spot.callsign||"")+": "+(external_spot.comments||"") + " ("+(external_spot.time.strftime("%H:%M:%S")||"")+")")
    cs.comments = cs.comments + [formatted_comment.slice(0, 255)]
    
    # 7. Persist and hand off to Step 3 Notifications Ledger
    if cs.changed?
      cs.save!
    end
  end
end

def consolidation_valid?(external_spot, consolidated_spot)
  #allow if code alrady there
  return true if consolidated_spot.code.include?(external_spot.code)


  # check that new assets overlap with old (VK/ZL)
  if external_spot.code.match?(/VK|ZL|AU|NZ/)
    logger.debug("SPOTCHECK: NZ/AU")
    if !Asset.overlap_all?(consolidated_spot.code, [ external_spot.code ])
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


def find_matching_consolidated_spot(external_spot)
  # 1. Clean the incoming matching variables exactly as your logic dictates
  incoming_khz = external_spot.frequency.present? ? (external_spot.frequency.to_d * 1000).to_d.truncate.to_i : 0
  base_call  = User.remove_call_suffix(external_spot.activatorCallsign||"UNKNOWN")
  incoming_mode = external_spot.mode.to_s.strip.upcase

  # 2. Build a clean, parameterized ActiveRecord relation
  ConsolidatedSpot.where(activatorCallsign: base_call)
    .where(
      "(updated_at > :max_consolidation) OR (:code = ANY(code) AND updated_at > :max_lifetime)",
      max_consolidation: MAX_SPOT_CONSOLIDATION_TIME.minutes.ago,
      max_lifetime:      MAX_SPOT_LIFETIME.minutes.ago,
      code:              external_spot.code
    )
    .where(
      "trunc(NULLIF(NULLIF(frequency,''), '0.0')::decimal * 1000) = :freq OR frequency IS NULL OR frequency = '' OR frequency = '0.0' OR :freq = '' OR :freq = '0'",
      freq: incoming_khz.to_s
    )
    .where(
      "COALESCE((SELECT parent_group FROM mode_mappings WHERE raw_mode = consolidated_spots.mode), consolidated_spots.mode) = " \
      "COALESCE((SELECT parent_group FROM mode_mappings WHERE raw_mode = :incoming_mode), :incoming_mode) " \
      "OR consolidated_spots.mode IS NULL OR consolidated_spots.mode = '' OR :incoming_mode = ''",
      incoming_mode: incoming_mode
    )
    .order(created_at: :desc)
    .first
end


