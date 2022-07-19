class SotaActivation < ActiveRecord::Base
 
def self.import
#  sas=self.all
#  sas.each do |sa|
#     sa.destroy
#  end

  summits=Asset.where(asset_type: "summit")
  summits.each do |summit|
    self.update_sota_activation(summit)
  end
end

def self.update_sota_activation(summit)
    puts "Summit: "+summit.code
    url = "https://api-db.sota.org.uk/admin/find_summit?search="+summit.code
    data = JSON.parse(open(url, {ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE}).read)
    if data and data[0] then
      summitId=data[0]["SummitId"]
      url = "https://api-db.sota.org.uk/admin/summit_history?summitID="+summitId.to_s
      data = JSON.parse(open(url, {ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE}).read)
      if data and data["activations"] then
        puts "Activations: "+data["activations"].count.to_s
        newcount=0
        data["activations"].each do |activation|
          sa=SotaActivation.new
          sa.callsign=activation["OwnCallsign"].strip
          sa.summit_code=summit.code.strip
          sa.summit_sota_id=summitId
          if activation["ActivationDate"] then sa.date=activation["ActivationDate"].to_date  end
          sa.qso_count=activation["QSOs"]
          dups=SotaActivation.where(sa.attributes.except("id", "updated_at", "created_at")).count
          if dups==0 then
            newcount+=1
            sa.save
            user=User.find_by(callsign: sa.callsign)
            if user then
              user.check_district_awards
              user.check_region_awards
            end 
          end
        end
        puts "New: "+newcount.to_s
      end
    end
  end
end
