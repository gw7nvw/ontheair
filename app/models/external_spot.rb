# frozen_string_literal: true

# typed: false
class ExternalSpot < ActiveRecord::Base
  validate :record_is_unique

  def record_is_unique
    dup = ExternalSpot.find_by(attributes.except('id', 'created_at', 'updated_at', 'epoch'))
    errors.add(:id, 'Record is duplicate') if dup
  end

  def self.delete_old_spots
    oneweekago=Time.at(Time.now.to_i - 60 * 60 * 24 * 7).in_time_zone('UTC').to_s
    ActiveRecord::Base.connection.execute("delete from external_spots where time < '#{oneweekago}'")

  end

  def self.fetch
    spots = nil

    # only fetch if last read > 30 secs past
    thirtysecondsago = Time.at(Time.now.to_i - 30).in_time_zone('UTC').to_s
    as = AdminSettings.first
    if !as.last_spot_read || (as.last_spot_read < thirtysecondsago)
      # update last read time
      as.last_spot_read = Time.now
      as.save

      # clear old spots > 1 week ago from DB
      ExternalSpot.delete_old_spots

      #SOTA
      spots=[]
      #Check 'epoch' latest spot update key
      epoch_url = 'https://api-db2.sota.org.uk/api/spots/epoch'
      as=AdminSettings.first
      old_epoch=as.sota_epoch
      new_epoch=open(epoch_url).read

      puts old_epoch
      puts new_epoch
      puts old_epoch==new_epoch
      #if epoch has chnaged, get new spots
      unless old_epoch==new_epoch 
        as.sota_epoch=new_epoch
        as.save

        begin
          Timeout.timeout(30) do
            # read new spots
            #url = 'https://api2.sota.org.uk/api/spots/50/all?client=sotawatch&user=anon'
            url = 'https://api-db2.sota.org.uk/api/spots/50/all/all'
  
            spots = JSON.parse(open(url).read)
            puts "GOT SOTA: "+spots.to_json
          end
        rescue Timeout::Error
          puts 'ERROR: SOTA Timeout'
        else
        end
      end

      zlvk_sota_spots = spots || []

      #POTA
      spots=[]
      begin
        Timeout.timeout(30) do
          url = 'https://api.pota.app/spot/activator'
          spots = JSON.parse(open(url).read)
          puts "GOT POTA: "+spots.to_json
        end
      rescue Timeout::Error
        puts 'ERROR: POTA Timeout'
      else
      end

      zlvk_pota_spots = spots || []

      #WWFF
      spots=[]
      begin
        Timeout.timeout(30) do
          url = 'https://spots.wwff.co/static/spots.json'
          spots = JSON.parse(open(url).read)
          puts "GOT WWFF: "+spots.to_json
        end
      rescue Timeout::Error
        puts 'ERROR: WWFF Timeout'
      else
      end

      wwff_spots = spots || []

      #Parks N Peaks
      spots=[]
      begin
        Timeout.timeout(30) do
          url = 'http://www.parksnpeaks.org/api/ALL'
          spots = JSON.parse(open(url).read)
          puts "GOT PnP: "+spots.to_json
        end
      rescue Timeout::Error
        puts 'ERROR: PnP Timeout'
      else
      end

      pnp_spots = spots || []

      #HEMA
      hemaspots = []
      begin
        Timeout.timeout(30) do
          url = 'http://hema.org.uk/spotsMobile.jsp'
          spots_string = open(url).read
          spots_list = spots_string.split('=')
          spots_list[1..-1].each do |spotstring|
            next unless spotstring && spotstring[';']
            puts spotstring
            spot = spotstring.split(';')
            hemaspot = { time: spot[0], activatorCallsign: spot[2], code: spot[3], name: spot[4], frequency: spot[5].split(' ')[0], mode: (spot[5] || '').split('(')[1].split(')')[0], callsign: (spot[6] || '').split('(')[1].split(')')[0], comments: (spot[6] || '').split(' ')[1], spot_type: 'HEMA' }
            hemaspot[:time] = (hemaspot[:time].to_datetime ? hemaspot[:time].to_datetime.in_time_zone('UTC') : nil)
            hemaspots += [hemaspot]
            puts 'done'
          end
        end
      rescue Timeout::Error
        puts 'ERROR: HEMA Timeout'
      else
      end

      # add to db
      zlvk_sota_spots.each do |spot|
        ExternalSpot.create(
          time: spot['timeStamp'].to_datetime ? spot['timeStamp'].to_datetime.in_time_zone('UTC') : nil,
          callsign: spot['callsign'].strip,
          activatorCallsign: spot['activatorCallsign'].strip,
          code: spot['summitCode'],
          name: spot['summitDetails'],
          frequency: spot['frequency'].to_s,
          mode: spot['mode'],
          comments: spot['comments'],
          epoch: spot['epoch'] || "",
          points: spot['points'].to_s || "",
          altM: spot['AltM'].to_s || "",
          is_test: (spot['type']=='TEST'),
          spot_type: 'SOTA'
        )
      end
     
      zlvk_pota_spots.each do |spot|
        ExternalSpot.create(
          time: spot['spotTime'].to_datetime ? spot['spotTime'].to_datetime.in_time_zone('UTC') : nil,
          callsign: spot['spotter'].strip,
          activatorCallsign: spot['activator'].strip,
          code: spot['reference'],
          name: spot['name'],
          frequency: (spot['frequency'].to_f / 1000).to_s,
          mode: spot['mode'],
          comments: spot['comments'],
          spot_type: 'POTA'
        )
      end
      pnp_spots.each do |spot|
        ExternalSpot.create(
          time: spot['actTime'].to_datetime ? spot['actTime'].to_datetime.in_time_zone('UTC') : nil,
          callsign: spot['actSpoter'].strip,
          activatorCallsign: spot['actCallsign'].strip,
          code: spot['WWFFid'] && !spot['WWFFid'].empty? ? spot['WWFFid'] : spot['actLocation'],
          name: spot['WWFFid'] && !spot['WWFFid'].empty? ? spot['actLocation'] : spot['altLocation'],
          frequency: spot['actFreq'],
          mode: spot['actMode'],
          comments: spot['actComments'],
          spot_type: 'PnP: ' + spot['actClass']
        )
      end
      wwff_spots.each do |spot|
        ExternalSpot.create(
          time: spot['spot_time_formatted'].to_datetime ? spot['spot_time_formatted'].to_datetime.in_time_zone('UTC') : nil,
          callsign: spot['spotter'].strip,
          activatorCallsign: spot['activator'].strip,
          code: spot['reference'] && !spot['reference'].empty? ? spot['reference'] : 'UNKNOWN',
          name: spot['reference_name'] && !spot['reference_name'].empty? ? spot['reference_name'] : 'UNKNOWN',
          frequency: (if spot['frequency_khz'].to_f then (spot['frequency_khz'].to_f/1000).to_s else "" end),
          mode: spot['mode'],
          comments: spot['remarks'],
          spot_type: 'WWFF'
        )
      end


      hemaspots.each do |spot|
        ExternalSpot.create(spot)
      end
    end
  end
end
