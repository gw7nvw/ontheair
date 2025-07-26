class ExternalAlert < ActiveRecord::Base

def self.fetch
    zlvk_sota_alerts = []
    zlvk_pota_alerts = []
    if !@tz then @tz=Timezone.find_by(name: 'UTC') end

    #ParksNPeaks
    begin
      url = 'http://parksnpeaks.org/api/ALERTS/'
      pnp_alerts = JSON.parse(open(url).read)
    rescue StandardError
      puts "Received invalid alert data from Parks'n'Peaks. Showing only local alerts"
      pnp_alerts = []
    end
    puts "#{pnp_alerts.count} alerts received"

    #POTA
    alerts=[]
    begin
      Timeout.timeout(30) do
        url = 'https://api.pota.app/activation'
        alerts = JSON.parse(open(url).read)
      end
    rescue Timeout::Error
      puts 'ERROR: POTA Timeout'
    else
    end

    pota_alerts = alerts || []

    puts "#{pota_alerts.count} alerts received"

    #WWFF
    begin
      url = 'https://spots.wwff.co/static/agendas.json'
      wwff_alerts = JSON.parse(open(url).read)
    rescue StandardError
      puts "Received invalid alert data from WWFF. Showing only local alerts"
      wwff_alerts = []
    end

    puts "#{wwff_alerts.count} alerts received"

    #SOTA
    sota_alerts=[]
    #Check 'epoch' latest spot update key
    epoch_url = 'https://api-db2.sota.org.uk/api/alerts/epoch'
    as=AdminSettings.first
    old_epoch=as.sota_alert_epoch
    new_epoch=open(epoch_url).read

    puts old_epoch
    puts new_epoch
    puts old_epoch==new_epoch
    #if epoch has chnaged, get new spots
    unless old_epoch==new_epoch
      as.sota_alert_epoch=new_epoch
      as.save

      begin
        url = 'https://api-db2.sota.org.uk/api/alerts'
        sota_alerts = JSON.parse(open(url).read)
      rescue StandardError
        puts "Received invalid alert data from SOTA. Showing only local alerts"
        sota_alerts = []
      end
    end
    puts "#{sota_alerts.count} alerts received"

    @all_alerts = []
    sota_alerts.each do |alert|
      @all_alerts.push(
           starttime: if alert["dateActivated"].to_time then alert["dateActivated"].to_time.in_time_zone(@tz.name).strftime("%Y-%m-%d %H:%M") else "" end,
           activatingCallsign: alert['activatingCallsign'].strip,
           code: alert['associationCode'] + '/' + alert['summitCode'],
           name: alert['summitDetails'],
           frequency: alert['frequency'],
           mode: alert['mode'],
           duration: "1",
           comments: (alert['comments']||"") + (if alert['posterCallsign'] and alert['posterCallsign'].length>0 then ' (de '+alert['posterCallsign']+')' else "" end),
           programme: 'SOTA'
      )
    end

    wwff_alerts.each do |alert|
      @all_alerts.push(
          starttime: if alert['utc_start'].to_datetime then alert['utc_start'].to_datetime.in_time_zone('UTC').strftime('%Y-%m-%d %H:%M') else "" end,
          duration: if alert['utc_start'].to_time and alert['utc_end'].to_time then ((alert['utc_end'].to_time-alert['utc_start'].to_time)/3600).to_s else "" end,
          activatingCallsign: alert['activator_call'].strip,
          code: alert['reference'],
          frequency: alert['band'],
          mode: alert['mode'],
          name: '['+alert['reference']+']',
          comments: alert['remarks']+(if alert['poster'] and alert['poster'].length>0 then ' (de '+alert['poster']+')' else "" end),
          programme: 'WWFF'
        )
    end

    pota_alerts.each do |alert|
      duration = 1
      if alert['startDate'] and alert['startTime'] and alert['endDate'] and alert['endTime'] then
        duration = (alert['endDate'] + ' ' + alert['endTime']).to_time - (alert['startDate'] + ' ' + alert['startTime']).to_time 
        duration = 1.0 * duration / 3600
      end
      @all_alerts.push(
          starttime: if alert['startDate'].to_datetime then (alert['startDate']+' '+alert['endTime']).to_datetime.in_time_zone(@tz.name).strftime('%Y-%m-%d %H:%M') else '' end,
          duration: duration,
          activatingCallsign: alert['activator'].strip,
          code: alert['reference'],
          name: alert['name'],
          frequency: alert['frequencies'],
          mode: '',
          comments: alert['comments'],
          programme: 'POTA'
        )
    end

    pnp_alerts.each do |alert|
      if !["SOTA", "ZLOTA"].include?(alert['Class']) then
        @all_alerts.push(
           starttime: if alert['alTime'].to_datetime then alert['alTime'].to_datetime.in_time_zone(@tz.name).strftime('%Y-%m-%d %H:%M') + ( if alert['alDay'] == '1' then ' (Day)' elsif alert['alDay'] == '2' then ' (Morning)' elsif alert['alDay'] == '3' then ' (Afternoon)' elsif alert['alDay'] == '4' then ' (Evening)' elsif alert['alDay'] == '5' then ' (Overnight)' else '' end) else '' end,
           activatingCallsign: alert['CallSign'].strip,
           code: alert['WWFFID'] && !alert['WWFFID'].empty? ? alert['WWFFID'] : alert['Location'],
           name: alert['Location'],
           frequency: alert['Freq'],
           mode: alert['MODE'],
           comments: alert['Comments'],
           programme: 'PnP: ' + alert['Class']
         )
      end
    end

    @all_alerts.each do |alert|
      #puts alert.to_json
      begin
        dups = ExternalAlert.where(starttime: alert[:starttime].tr('A-Z,a-z,[()]','').strip, activatingCallsign: alert[:activatingCallsign], code: alert[:code], frequency: alert[:frequency], mode: alert[:mode], programme: alert[:programme])
        if !(dups && dups.count.positive?)
           puts "Creating alert: "+alert.to_json.to_s
           ExternalAlert.create(alert) 
        end
      rescue StandardError
        puts "Failed to add an external alert with invalid formatting"
      end

    end

    #tidy up
    oneweekago=Time.at(Time.now.to_i - 60 * 60 * 24 * 7).in_time_zone('UTC').to_s

    ActiveRecord::Base.connection.execute("delete from external_alerts where starttime < '#{oneweekago}'")

  @all_alerts

end

def self.import_hota_alerts(alerts)
  all_alerts=[]
  alerts.each do |alert|
    ext_alert=ExternalAlert.new(id: -alert.item_id, starttime: alert.referenced_date, duration: alert.duration, activatingCallsign: alert.callsign, code: alert.asset_codes, name: alert.site, frequency: alert.freq, mode: alert.mode, comments: alert.description, programme: 'ZLOTA')
    all_alerts+=[ext_alert] 
  end 
  all_alerts
end
end

