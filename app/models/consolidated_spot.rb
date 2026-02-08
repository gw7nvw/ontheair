class ConsolidatedSpot < ActiveRecord::Base

  include MapHelper

  before_save :add_band
  after_save :create_notifications

  def before_save_actions
     add_band
     self.comments=self.comments[0..254] if self.comments
  end

  def self.delete_old_spots
    oneweekago=Time.at(Time.now.to_i - 60 * 60 * 24 * 7).in_time_zone('UTC').to_s
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
    is_new = true if !self.old_spot_type

    programme_array = self.spot_type.map { |a| "'%%:programme:%%"+a+"%%'"}.join(", ")
    old_programme_array = self.old_spot_type.map { |a| "'%%:programme:%%"+a+"%%'"}.join(", ")
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
        system("rm #{filename}")

      end
    end
    self.update_column :old_spot_type, self.spot_type
  true
  end
end
