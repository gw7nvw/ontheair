class ExternalAlert < ApplicationRecord
  before_save { before_save_actions }

  attribute :codes, :string, array: true, default: -> { [] }
  after_find :set_default_codes
  attr_accessor :is_qrp

  def get_codes
    if codes and codes.count>0 then codes else [ code ] end
  end

  def before_save_actions
     add_dxcc
     self.comments=self.comments[0..254] if self.comments
  end

  def add_dxcc
    if !self.dxcc or !self.continent then
      reference = code if code
      if reference  then
        dxccs = DxccPrefix.find_by("'#{reference}' like concat(iso_code,'-%%') or '#{reference}' like concat(iso_code,'LL-%%')")
        dxccs = DxccPrefix.find_by("'#{reference}' like concat(prefix,'FF-%%') or '#{reference}' like concat(prefix,'-%%') or '#{reference}' like concat(prefix,'_/%%')") if !dxccs

        self.dxcc = dxccs.prefix if dxccs
        self.continent = dxccs.continent_code if dxccs
      end
    end
  end

def self.fetch
    zlvk_sota_alerts = []
    zlvk_pota_alerts = []
    if !@tz then @tz=Timezone.find_by(name: "UTC") end

    # ParksNPeaks
    #    begin
    #      url = 'http://parksnpeaks.org/api/ALERTS/'
    #      pnp_alerts = JSON.parse(open(url).read)
    #    rescue StandardError
    #      puts "Received invalid alert data from Parks'n'Peaks. Showing only local alerts"
    #      pnp_alerts = []
    #    end
    #    puts "#{pnp_alerts.count} alerts received"

    # POTA
    alerts=[]
    begin
      Timeout.timeout(30) do
        url = "https://api.pota.app/activation"
        raw_response = fetch_external_url(url)
        alerts = JSON.parse(raw_response.blank? ? "[]" : raw_response)
      end
    rescue Timeout::Error
      puts "ERROR: POTA Timeout"
    else
    end

    pota_alerts = alerts || []

    puts "#{pota_alerts.count} POTA alerts received"

    # WWFF
    begin
      url = "https://spots.wwff.co/static/agendas.json"
      raw_response = fetch_external_url(url)
      wwff_alerts = JSON.parse(raw_response.blank? ? "[]" : raw_response)

    rescue StandardError
      puts "Received invalid alert data from WWFF. Showing only local alerts"
      wwff_alerts = []
    end

    puts "#{wwff_alerts.count} WWFF alerts received"

    # SOTA
    sota_alerts=[]
    # Check 'epoch' latest spot update key
    epoch_url = "https://api-db2.sota.org.uk/api/alerts/epoch"
    as=AdminSettings.first
    old_epoch=as.sota_alert_epoch
    new_epoch = fetch_external_url(epoch_url)

    # if epoch has chnaged, get new spots
    unless old_epoch==new_epoch
      as.sota_alert_epoch=new_epoch
      as.save

 #     begin
        url = "https://api-db2.sota.org.uk/api/alerts"
        raw_response = fetch_external_url(url)
        sota_alerts = JSON.parse(raw_response.blank? ? "[]" : raw_response)
 #     rescue StandardError
 #       puts "Received invalid alert data from SOTA. Showing only local alerts"
 #       sota_alerts = []
 #     end
    end
    puts "#{sota_alerts.count} SOTA alerts received"

    @all_alerts = []
    api_source_ids=[]

    sota_alerts.each do |alert|
      @all_alerts.push(
           source: "SOTA",
           source_id: alert["id"],
           starttime: if alert["dateActivated"].to_time then alert["dateActivated"].to_time.in_time_zone(@tz.name).strftime("%Y-%m-%d %H:%M") else "" end,
           activatingCallsign: alert["activatingCallsign"].strip,
           code: (alert["associationCode"] + "/" + alert["summitCode"]).gsub("?", "X"),
           name: alert["summitDetails"],
           frequency: alert["frequency"],
           mode: alert["mode"],
           duration: "1",
           comments: (alert["comments"]||"") + (if alert["posterCallsign"] and alert["posterCallsign"].length>0 then " (de "+alert["posterCallsign"]+")" else "" end),
           programme: "SOTA"
      )
      api_source_ids << alert["id"]
    end
    synch_deletions('SOTA', api_source_ids)

    api_source_ids=[]
    wwff_alerts.each do |alert|
      @all_alerts.push(
          source: "WWFF",
          source_id:  alert['id'],
          starttime: if alert["utc_start"].to_datetime then alert["utc_start"].to_datetime.in_time_zone("UTC").strftime("%Y-%m-%d %H:%M") else "" end,
          duration: if alert["utc_start"].to_time and alert["utc_end"].to_time then ((alert["utc_end"].to_time-alert["utc_start"].to_time)/3600).to_s else "" end,
          activatingCallsign: alert["activator_call"].strip,
          code: alert["reference"],
          frequency: alert["band"],
          mode: alert["mode"],
          name: "["+alert["reference"]+"]",
          comments: alert["remarks"]+(if alert["poster"] and alert["poster"].length>0 then " (de "+alert["poster"]+")" else "" end),
          programme: "WWFF"
        )
      api_source_ids << alert["id"]
    end
    synch_deletions('WWFF', api_source_ids)

    api_source_ids=[]
    pota_alerts.each do |alert|
      duration = 1
      if alert["startDate"] and alert["startTime"] and alert["endDate"] and alert["endTime"] then
        duration = (alert["endDate"] + " " + alert["endTime"]).to_time - (alert["startDate"] + " " + alert["startTime"]).to_time
        duration = 1.0 * duration / 3600
      end
      @all_alerts.push(
          source: 'POTA',
          source_id: alert['scheduledActivitiesId'],
          starttime: if alert["startDate"].to_datetime then (alert["startDate"]+" "+alert["startTime"]).to_datetime.in_time_zone(@tz.name).strftime("%Y-%m-%d %H:%M") else "" end,
          duration: duration,
          activatingCallsign: alert["activator"].strip,
          code: alert["reference"],
          name: alert["name"],
          frequency: alert["frequencies"],
          mode: "",
          comments: alert["comments"],
          programme: "POTA"
        )
      api_source_ids << alert["scheduledActivitiesId"]
    end
    synch_deletions('POTA', api_source_ids)

    puts "TOTAL #{@all_alerts.count} alerts"
    puts ExternalAlert.count
    @all_alerts.each do |alert|
      # puts alert.to_json
      begin
        dups = ExternalAlert.where(starttime: alert[:starttime].tr("A-Z,a-z,[()]", "").strip, activatingCallsign: alert[:activatingCallsign], code: alert[:code], frequency: alert[:frequency], mode: alert[:mode], programme: alert[:programme],comments: alert[:comments])
        if !(dups && dups.count.positive?)
           #puts "Deleting old records with source='#{alert[:source]}' AND source_id=#{alert[:source_id]}"
           ActiveRecord::Base.connection.execute("DELETE FROM external_alerts WHERE source='#{alert[:source]}' AND source_id=#{alert[:source_id]}") if alert[:source] and alert[:source_id]
           #puts "Creating alert: "+alert.to_json.to_s
           result=ExternalAlert.create(alert)
           puts "ERROR: Create alert failed" if !result
        end
      rescue StandardError
        puts "Failed to add an external alert with invalid formatting"
      end
    end
    puts ExternalAlert.count

    # tidy up
    oneweekago=Time.at(Time.now.to_i - 60 * 60 * 24 * 7).in_time_zone("UTC").to_s

    if ENV["RAILS_ENV"]!="test"
      puts "PURGING OLD ALERTS"
      ActiveRecord::Base.connection.execute("delete from external_alerts where starttime + (duration::float * interval '1 hour') < '#{oneweekago}'"); puts "PURGING" if ENV["RAILS_ENV"]!="test"
    end

  @all_alerts
end

def self.synch_deletions(source, api_source_ids)
  return if !api_source_ids or api_source_ids.count==0

  local_future_ids = ExternalAlert.where(source: source)
      .where("starttime > ?", Time.current + 5.minutes)
      .pluck(:source_id)
  missing_ids = local_future_ids - api_source_ids
  if missing_ids.any?
    ExternalAlert.where(source: source, source_id: missing_ids).delete_all
  end
end


def self.import_hota_alerts(alerts)
  all_alerts=[]
  alerts.each do |alert|
    code = alert.asset_codes.first
    dxcc = ""
    continent = Continent.find_by(code: "OC")
    asset = Asset.find_by(code: code)
    programme="UNKNOWN" # default
    programme='QRP' if alert.is_qrp #Default for QRP
    if asset then
      dxcc = asset.country
      dxccs = DxccPrefix.find_by(prefix: dxcc)
      continent = dxccs.continent
      programme=asset.type.pnp_class
    end
    ext_alert=ExternalAlert.new(id: -(alert.item_id||alert.temp_item_id), starttime: alert.referenced_time, duration: alert.duration, activatingCallsign: alert.callsign, codes: alert.asset_codes, name: alert.site, frequency: alert.freq, mode: alert.mode, comments: alert.description, programme: programme, dxcc: dxcc, continent: continent.code, code: code, is_qrp: alert.is_qrp)
    all_alerts+=[ ext_alert ]
  end
  all_alerts
end

  private

  def set_default_codes
    self.codes = [ self.code ]
  end
end
