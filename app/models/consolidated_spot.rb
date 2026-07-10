class ConsolidatedSpot < ActiveRecord::Base

  include MapHelper

  before_save {before_save_actions}
  after_save :create_notifications

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
        dxccs = DxccPrefix.find_by("'#{reference}' like concat(iso_code,'-%%') or '#{reference}' like concat(iso_code,'LL-%%')")
        dxccs = DxccPrefix.find_by("'#{reference}' like concat(prefix,'FF-%%') or '#{reference}' like concat(prefix,'/%%') or '#{reference}' like concat(prefix,'_/%%')") if !dxccs
        #VK SIOTA
        dxccs = DxccPrefix.find_by(prefix: 'VK') if !dxccs and reference.match(/^VK-.*/)
        self.dxcc = dxccs.prefix if dxccs
        self.continent = dxccs.continent_code if dxccs
      end 
    end
  end

  def self.delete_old_spots
    #keepng spots for a year
    oneweekago=Time.at(Time.now.to_i - 60 * 60 * 24 * 365).in_time_zone('UTC').to_s
    ActiveRecord::Base.connection.execute("delete from consolidated_spots where updated_at < '#{oneweekago}'")
  end

  def continent
    DxccPrefix.continent_from_call(self.activatorCallsign)
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
    summary = activatorCallsign + ' spotted on ' + ((self.frequency && !self.frequency.empty?) || (self.mode && !self.mode.empty?) ? self.frequency + ' - ' + self.mode : 'UNKNOWN') + ' at ' + (sites && sites.count.positive? ? sites.first + (if sites && (sites.count > 1) then ' et al.' else '' end) : 'UNKNOWN')
  end

  def url
    "https://ontheair.nz/spots"
  end


  def self.check_pnp2_spots(zone)
    sql = <<-SQL
      SELECT 
        round(EXTRACT(EPOCH FROM max(updated_at))::numeric,0) as "lastUpdatedAt"
        FROM consolidated_spots
        WHERE (:zone = 'ALL' OR continent = :zone)
        ORDER BY time DESC
        LIMIT 1;
    SQL

    # 2. Bind the variables safely (Double-check that start_time and zone are not nil)
    sanitized_sql = sanitize_sql_array([sql, { zone: zone }])
    
    connection.select_all(sanitized_sql)
  end

  def self.get_pnp2_spots(start_time, zone)
    sql = <<-SQL
      SELECT 
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
        WHERE updated_at >= :start_time::timestamptz 
             AND (:zone = 'ALL' OR continent = :zone)
        ORDER BY time DESC;
    SQL

    # 2. Bind the variables safely (Double-check that start_time and zone are not nil)
    sanitized_sql = sanitize_sql_array([sql, { start_time: start_time, zone: zone }])
    
    find_by_sql(sanitized_sql).map(&:attributes)
  end
 
  def self.get_pnp_spots(start_time, zone)
    sql = <<-SQL
      SELECT jsonb_agg(spot_json) AS final_payload FROM (
        SELECT 
         (
           jsonb_build_object(
             'actTime', f.t_val, 'actId', f.id, 'actSiteID', f.c_val, 'ID', f.c_val,
             'actCallsign', f."activatorCallsign", 'actMode', f.mode,
             'actComments', CASE WHEN LENGTH(f.codes_str) - LENGTH(REPLACE(f.codes_str, ',', '')) > 0 THEN CONCAT('[', f.codes_str, '] ', f.comm_val) ELSE f.comm_val END,
             'actFreq', f.frequency, 'actClass', f.st_val, 'altLocation', f.n_val, 'actSpoter', f.cs_val,
             'actLocation', CASE WHEN f.st_val IN ('SOTA', 'SIOTA', 'SHIRES', 'ZLOTA') THEN f.c_val ELSE f.n_val END
           ) ||
           jsonb_strip_nulls(
             jsonb_build_object(
               'WWFFid', f.code_array[array_position(f.spot_type_array, 'WWFF')],
               'WWFFID', f.code_array[array_position(f.spot_type_array, 'WWFF')],
               'ParkID', f.code_array[array_position(f.spot_type_array, 'WWFF')],
               'POTAID', f.code_array[array_position(f.spot_type_array, 'POTA')],
               'SOTAID', f.code_array[array_position(f.spot_type_array, 'SOTA')],
               'SANPCPAID', f.code_array[array_position(f.spot_type_array, 'SANPCPA')],
               'KRMNPAID', f.code_array[array_position(f.spot_type_array, 'KRMNPA')]
             )
           )
         ) AS spot_json
        FROM ( 
           SELECT id, "activatorCallsign", mode, frequency, code AS code_array, spot_type AS spot_type_array,
               time[cardinality(time)] AS t_val, code[cardinality(code)] AS c_val, spot_type[cardinality(spot_type)] AS st_val,
               name[cardinality(name)] AS n_val, callsign[cardinality(callsign)] AS cs_val,
               TRIM(REGEXP_REPLACE(LEFT(comments[cardinality(comments)], -10), '^[^:]*:', '')) AS comm_val,
               array_to_string(ARRAY(SELECT DISTINCT unnest(code)), ', ') AS codes_str
           FROM consolidated_spots
           WHERE updated_at >= :start_time::timestamptz 
             AND (:zone = 'ALL' OR continent = :zone)
        ) as f
        ORDER BY f.t_val DESC
      ) as sub;
    SQL

    # 2. Bind the variables safely (Double-check that start_time and zone are not nil)
    sanitized_sql = sanitize_sql_array([sql, { start_time: start_time, zone: zone }])
    
    # 3. Pull raw string text directly from the execution block
    connection.select_value(sanitized_sql) || '[]'
  end
 
  def get_subs(programme_array)
    if !programme_array.blank?
      subs = User.find_by_sql [ "
        SELECT * from users where \
            push_include_external is true  \
          AND \
            (push_external_filter not like '%%:programme:%%' or push_external_filter LIKE ANY ( ARRAY [#{programme_array}] )) \
          AND \
            (push_external_filter not like '%%:continent:%%' or push_external_filter LIKE '%%:continent:%%#{self.continent}%%') \
          AND \
            (push_external_filter not like '%%:mode:%%' or push_external_filter ILIKE '%%:mode:%%#{self.mode}%%') \
          AND \
            (push_external_filter not like '%%:band:%%' or push_external_filter ILIKE '%%:band:%%#{self.band}%%') \
          AND \
            (push_external_filter not like '%%:callsign:%%' or '#{self.activatorCallsign}' ILIKE ANY ( ARRAY ( select string_to_array ( array_to_string(regexp_matches(replace(push_external_filter,'\"',''), ':callsign: ([a-zA-Z0-9\\-\\/\\\%%,]+).*'),''), ',')))) \
          AND \
            (push_external_filter not like '%%:reference:%%' or '#{self.code.join(", ")}' ILIKE ANY ( ARRAY ( select string_to_array ( array_to_string(regexp_matches(replace(push_external_filter,'\"',''), ':reference: ([a-zA-Z0-9\\-\\/\\\%%,]+).*'),''), ',')))) \
        ;" ]
    else
      []
    end
  end

  def create_notifications
   if ENV['RAILS_ENV'] == 'production'
    is_new = true if !self.old_spot_type

    programme_array = self.spot_type.map { |a| "'%%:programme:%%"+a.to_s+"%%'"}.join(", ")
    old_programme_array = self.old_spot_type.map { |a| "'%%:programme:%%"+a.to_s+"%%'"}.join(", ")
    if is_new or programme_array != old_programme_array then
      if is_new then
        subs = self.get_subs(programme_array)
      else
        old_subs = self.get_subs(old_programme_array)
        new_subs = self.get_subs(programme_array) 
        subs = new_subs - old_subs
      end 

      if subs and subs.count>0 
        raw_image = nil
        if self.post_id and self.post_id.count>0 then
          i = Item.find(post_id.first.to_i)
          raw_image = i.raw_image if i
        else
          #check for coords
          assets = Asset.assets_from_code(self.code.join(', '))
          # should probaby use get_most_accurate ... but for simplicity
          asset = assets.first
          asset = asset[:asset] if asset
          location = asset.location if asset
  
          filename = get_3857_map_x_y(location.x,location.y, 9, 3, 3, "cons_"+self.id.to_s) if location
          image = File.read(filename) if filename
          raw_image = Base64.encode64(image) if image
        end
  
        
        subs.each do |sub|
          filter = sub.push_external_filter
          puts "send notification to #{sub.callsign}"
          sub.send_notification(summary, self.url, if sub.push_include_comments then self.comments.last else nil end, if sub.push_include_map then raw_image else nil end) 
        end
        system("rm #{filename}") if filename

      end
    end
    self.update_column :old_spot_type, self.spot_type
   end
  true
  end
end
