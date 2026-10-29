class ConsolidatedSpot < ActiveRecord::Base
  include MapHelper

  before_save { before_save_actions }
  after_commit :trigger_notifications, on: [:create, :update]

  def before_save_actions
     add_band
     add_dxcc
     self.comments=self.comments[0..254] if self.comments
     self.spot_type = self.spot_type.compact if self.spot_type
  end

  def add_dxcc
    if !self.dxcc or !self.continent then
      reference = code.first if code
      if reference  then
        dxccs = DxccPrefix.find_by("'#{reference}' like concat(iso_code,'-%%') or '#{reference}' like concat('LL',iso_code,'-%%')")
        dxccs = DxccPrefix.find_by("'#{reference}' like concat(prefix,'FF-%%') or '#{reference}' like concat(prefix,'/%%') or '#{reference}' like concat(prefix,'_/%%')") if !dxccs

        # VK SIOTA
        dxccs = DxccPrefix.find_by(prefix: "VK") if !dxccs and reference.match(/^VK-.*/)
        # ILLW
        dxccs = DxccPrefix.find_by("'#{reference}' like concat(iso_code,'0%%')") if !dxccs
        if dxccs 
          self.dxcc = dxccs.prefix 
          self.continent = dxccs.continent_code
        end
      end

      # fall back on callsign analysis
      if !self.dxcc
        dxcc = DxccPrefix.from_call(self.activatorCallsign)
        if dxcc
          self.dxcc = dxcc.prefix
          self.continent = dxcc.continent_code
        end
      end
    end
  end

  def self.delete_old_spots
    # keepng spots for a year
    oneyearago=Time.at(Time.now.to_i - 60 * 60 * 24 * 365).in_time_zone("UTC").to_s
    ActiveRecord::Base.connection.execute("delete from consolidated_spots where updated_at < '#{oneyearago}'")
  end

  def add_band
    self.band=Contact.band_from_frequency(frequency.to_f) if frequency
  end

  def summary
    if self.code then
      sites = self.code
    else
      sites = []
    end
    summary = activatorCallsign + " spotted on " + ((self.frequency && !self.frequency.empty?) || (self.mode && !self.mode.empty?) ? self.frequency + " - " + self.mode : "UNKNOWN") + " at " + (sites && sites.count.positive? ? sites.first + (if sites && (sites.count > 1) then " et al." else "" end) : "UNKNOWN")
  end

  def url
    "https://ontheair.nz/spots"
  end


  def self.check_pnp2_spots(zone)
    sql = <<-SQL
      SELECT#{' '}
        round(EXTRACT(EPOCH FROM max(updated_at))::numeric,0) as "lastUpdatedAt"
        FROM consolidated_spots
        WHERE (:zone = 'ALL' OR continent = :zone)
        ORDER BY time DESC
        LIMIT 1;
    SQL

    # 2. Bind the variables safely (Double-check that start_time and zone are not nil)
    sanitized_sql = sanitize_sql_array([ sql, { zone: zone } ])

    connection.select_all(sanitized_sql)
  end

  def self.get_pnp2_spots(start_time, zone)
    sql = <<-SQL
      SELECT#{' '}
        id as "spotID",
        updated_at as "updatedAt",
        "activatorCallsign",
        callsign[cardinality(callsign)] AS "lastSpotterCallsign",
        frequency,
        mode,
        band,
        dxcc,
        continent,
        (SELECT ARRAY_AGG(ARRAY[c, t, n])
            FROM unnest(code, spot_type, name) AS elements(c, t, n)
        ) AS location,
        comments as comments
        FROM consolidated_spots
        WHERE updated_at >= :start_time::timestamptz#{' '}
             AND (:zone = 'ALL' OR continent = :zone)
        ORDER BY time DESC;
    SQL

    # 2. Bind the variables safely (Double-check that start_time and zone are not nil)
    sanitized_sql = sanitize_sql_array([ sql, { start_time: start_time, zone: zone } ])

    find_by_sql(sanitized_sql).map(&:attributes)
  end

  def self.get_pnp_spots(start_time, zone)
sql = <<-SQL
  SELECT jsonb_agg(spot_json) AS final_payload FROM (
    SELECT#{' '}
     (
       jsonb_build_object(
         'actTime', replace(f.t_val, ' UTC', ''),
         'actId', f.id,#{' '}
         'actCallsign', f."activatorCallsign",#{' '}
         'actMode', f.mode,
         'actComments', CASE WHEN LENGTH(f.codes_str) - LENGTH(REPLACE(f.codes_str, ',', '')) > 0 THEN CONCAT('[', f.codes_str, '] ', f.comm_val) ELSE f.comm_val END,
         'actFreq', f.frequency,#{' '}
         'actSpoter', f.cs_val,
         'actClass', f.chosen_class,#{' '}
         'actSiteID', f.code_array[array_position(f.spot_type_array, f.chosen_class)],
         'ID', f.code_array[array_position(f.spot_type_array, f.chosen_class)],
         'altLocation', f.name_array[cardinality(name_array)],
         'actLocation', CASE#{' '}
           WHEN f.chosen_class IN ('SOTA', 'SIOTA', 'SHIRES', 'ZLOTA')#{' '}
           THEN f.code_array[array_position(f.spot_type_array, f.chosen_class)]#{' '}
           ELSE f.name_array[cardinality(name_array)]
         END
       ) ||
       jsonb_strip_nulls(
         jsonb_build_object(
           'WWFFid', f.code_array[array_position(f.spot_type_array, 'WWFF')],
           'WWFFID', f.code_array[array_position(f.spot_type_array, 'WWFF')],
           'ParkID', f.code_array[array_position(f.spot_type_array, 'WWFF')],
           'POTAID', f.code_array[array_position(f.spot_type_array, 'POTA')],
           'SOTAID', f.code_array[array_position(f.spot_type_array, 'SOTA')],
           'ZLOTAID', f.code_array[array_position(f.spot_type_array, 'ZLOTA')],
           'LLOTAID', f.code_array[array_position(f.spot_type_array, 'LLOTA')],
           'SIOTAID', f.code_array[array_position(f.spot_type_array, 'SIOTA')],
           'ILLWID', f.code_array[array_position(f.spot_type_array, 'ILLW')],
           'SANPCPAID', f.code_array[array_position(f.spot_type_array, 'SANPCPA')],
           'KRMNPAID', f.code_array[array_position(f.spot_type_array, 'KRMNPA')]
         )
       )
     ) AS spot_json
    FROM (#{' '}
       SELECT id, "activatorCallsign", mode, frequency, code AS code_array, spot_type AS spot_type_array, name AS name_array,
           time[cardinality(time)] AS t_val,#{' '}
           callsign[cardinality(callsign)] AS cs_val,
           spot_type[cardinality(spot_type)] AS st_val,
           TRIM(REGEXP_REPLACE(LEFT(comments[cardinality(comments)], -10), '^[^:]*:', '')) AS comm_val,
           array_to_string(ARRAY(SELECT DISTINCT unnest(code)), ', ') AS codes_str,
  #{'         '}
           -- Unified priority engine
           COALESCE(
             CASE WHEN 'SOTA' = ANY(spot_type) THEN 'SOTA' END,
             CASE WHEN 'WWFF' = ANY(spot_type) THEN 'WWFF' END,
             CASE WHEN 'SIOTA' = ANY(spot_type) THEN 'SIOTA' END,
             CASE WHEN 'HEMA' = ANY(spot_type) THEN 'HEMA' END,
             spot_type[cardinality(spot_type)]
           )::varchar AS chosen_class
       FROM consolidated_spots
       WHERE updated_at >= :start_time::timestamptz#{' '}
         AND (:zone = 'ALL' OR continent = :zone)
    ) as f
    ORDER BY f.t_val DESC
  ) as sub;
SQL

    # 2. Bind the variables safely (Double-check that start_time and zone are not nil)
    sanitized_sql = sanitize_sql_array([ sql, { start_time: start_time, zone: zone } ])

    # 3. Pull raw string text directly from the execution block
    connection.select_value(sanitized_sql) || "[]"
  end


  def trigger_notifications
    puts "Processing notifications for #{self.to_json}"
    # 1. Determine if this was a brand-new insert or an update
    # transaction_include_any_action?(:create) is the foolproof Rails way 
    # to detect a true INSERT state within an after_commit callback.
    is_new_record = transaction_include_any_action?([:create])

    # 2. For updates, confirm that significant data actually changed.
    # If a user just updates an unrelated admin flag or timestamp, we don't spam notifications.
    if !is_new_record
      significant_fields = ['frequency', 'mode', 'code', 'activatorCallsign']
      changed_fields = (significant_fields & saved_changes.keys) 
      return unless changed_fields.any?

      # No notifications if frequency stays within the KHz
      if changed_fields==['frequency'] and saved_change_to_frequency
        old_frequency, new_frequency = saved_change_to_frequency
        return if old_frequency.to_d.truncate(3)!=new_frequency.to_d.truncate(3)
      end
    end


    if ENV["RAILS_ENV"] == "production"
      puts "Enqueue notification"
      Resque.enqueue(::SendNotifications, self.id, is_new_record)
    else
      puts "send real-time notification"
      SendNotifications.perform(self.id, is_new_record)
    end
  end
end
