class ExternalAlert < ActiveRecord::Base

def self.fetch
    zlvk_sota_alerts = []
    zlvk_pota_alerts = []
    if !@tz then @tz=Timezone.find_by(name: 'UTC') end

    begin
      url = 'http://parksnpeaks.org/api/ALERTS/'
      pnp_alerts = JSON.parse(open(url).read)
    rescue StandardError
      puts "Received invalid alert data from Parks'n'Peaks. Showing only local alerts"
      pnp_alerts = []
    end
    puts "#{pnp_alerts.count} alerts received"

    begin
      url = 'https://spots.wwff.co/static/agendas.json'
      wwff_alerts = JSON.parse(open(url).read)
    rescue StandardError
      puts "Received invalid alert data from WWFF. Showing only local alerts"
      wwff_alerts = []
    end

    puts "#{wwff_alerts.count} alerts received"

    @all_alerts = []
    zlvk_sota_alerts.each do |alert|
      @all_alerts.push(
           starttime: if alert["dateActivated"].to_datetime then alert["dateActivated"].to_datetime.in_time_zone(@tz.name).strftime("%Y-%m-%d %H:%M") else "" end,
           activatingCallsign: alert['activatingCallsign'].strip,
           code: alert['associationCode'] + '/' + alert['summitCode'],
           name: alert['summitDetails'],
           frequency: alert['frequency'],
           mode: alert['mode'],
           comments: alert['comments'],
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

    zlvk_pota_alerts.each do |alert|
      @all_alerts.push(
          starttime: if alert['Start Date'].to_datetime then alert['Start Date'].to_datetime.in_time_zone(@tz.name).strftime('%Y-%m-%d %H:%M') + (if alert['End Date'].to_datetime then ' to ' + alert['End Date'].to_datetime.in_time_zone(@tz.name).strftime('%Y-%m-%d %H:%M') else '' end) else '' end,
          activatingCallsign: alert['Activator'].strip,
          code: alert['Reference'],
          name: alert['Park Name'],
          frequency: alert['Frequecies'],
          mode: '',
          comments: alert['Comments'],
          programme: 'POTA'
        )
    end

    pnp_alerts.each do |alert|
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

    @all_alerts.each do |alert|
      puts alert.to_json
      dups = ExternalAlert.where(starttime: alert[:starttime], activatingCallsign: alert[:activatingCallsign], code: alert[:code], frequency: alert[:frequency], mode: alert[:mode], programme: alert[:programme])
      if !(dups && dups.count.positive?)
         puts "Creating alert: "+alert.to_json.to_s
         ExternalAlert.create(alert) 
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
    ext_alert=ExternalAlert.new(starttime: alert.referenced_date, duration: alert.duration, activatingCallsign: alert.callsign, code: alert.asset_codes, name: alert.site, frequency: alert.freq, mode: alert.mode, comments: alert.description, programme: 'ZLOTA')
    all_alerts+=[ext_alert] 
  end 
  all_alerts
end
end

