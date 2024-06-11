class ExternalSpot < ActiveRecord::Base

validate :record_is_unique

def record_is_unique
  dup=ExternalSpot.find_by(self.attributes.except('id','created_at', 'updated_at'))
  if dup then 
     errors.add(:id, "Record is duplicate") 
  end
end

def self.fetch

    spots=nil

    #only fetch if last read > 30 secs past
    thirtysecondsago=Time.at(Time.now().to_i-30).in_time_zone('UTC').to_s
    as=AdminSettings.first
    if !as.last_spot_read or as.last_spot_read<thirtysecondsago then
      #update last read time
      as.last_spot_read=Time.now()
      as.save
 
      #clear old spots > 1 year ago from DB
      oneyearago=Time.at(Time.now().to_i-60*60*24*365).in_time_zone('UTC').to_s

      begin
        Timeout::timeout(30) {
          #read new spots
          url="https://api2.sota.org.uk/api/spots/50/all?client=sotawatch&user=anon"
          spots=JSON.parse(open(url).read)
        }
      rescue Timeout::Error
        puts "ERROR: SOTA Timeout"
      else
      end

      if spots then
        zlvk_sota_spots=spots
      else
        zlvk_sota_spots=[]
      end


      begin
        Timeout::timeout(30) {
          url="https://api.pota.app/spot/activator"
          spots=JSON.parse(open(url).read)
      }
      rescue Timeout::Error
        puts "ERROR: POTA Timeout"
      else
      end

      if spots then
        zlvk_pota_spots=spots
      else
        zlvk_pota_spots=[]
      end

      begin
        Timeout::timeout(30) {
        url="http://www.parksnpeaks.org/api/ALL"
        spots=JSON.parse(open(url).read)
      }
      rescue Timeout::Error
        puts "ERROR: PnP Timeout"
      else
      end

      if spots then
        pnp_spots=spots
      else
        pnp_spots=[]
      end

      #add to db
      zlvk_sota_spots.each do |spot|
         new_spot=ExternalSpot.create(
           time: if spot["timeStamp"].to_datetime then spot["timeStamp"].to_datetime.in_time_zone('UTC') else nil end,
           callsign: spot["callsign"].strip,
           activatorCallsign: spot["activatorCallsign"].strip,
           code: spot["associationCode"]+"/"+spot["summitCode"],
           name: spot["summitDetails"],
           frequency: spot["frequency"],
           mode: spot["mode"],
           comments: spot["comments"],
           spot_type: "SOTA")
      end

      zlvk_pota_spots.each do |spot|
         new_spot=ExternalSpot.create(
           time: if spot["spotTime"].to_datetime then spot["spotTime"].to_datetime.in_time_zone('UTC') else nil end,
           callsign: spot["spotter"].strip,
           activatorCallsign: spot["activator"].strip,
           code: spot["reference"],
           name: spot["name"],
           frequency: ((spot["frequency"].to_f)/1000).to_s,
           mode: spot["mode"],
           comments: spot["comments"],
           spot_type: "POTA")
      end
      pnp_spots.each do |spot|
        new_spot=ExternalSpot.create(
           time: if spot["actTime"].to_datetime then spot["actTime"].to_datetime.in_time_zone('UTC') else nil end,
           callsign: spot["actSpoter"].strip,
           activatorCallsign: spot["actCallsign"].strip,
           code: if spot["WWFFid"] and spot["WWFFid"].length>0 then spot["WWFFid"] else spot["actLocation"] end,
           name: if spot["WWFFid"] and spot["WWFFid"].length>0 then spot["actLocation"] else spot["altLocation"] end,
           frequency: spot["actFreq"],
           mode: spot["actMode"],
           comments: spot["actComments"],
           spot_type: "PnP: "+spot["actClass"])
      end

    end
end

end
