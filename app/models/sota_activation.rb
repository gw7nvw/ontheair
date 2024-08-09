class SotaActivation < ActiveRecord::Base

before_save { self.before_save_actions }

def before_save_actions
  self.remove_suffix
  self.add_user_ids
end

def add_user_ids
    #look up callsign1 at contact.time
    user=User.find_by_callsign_date(self.callsign, self.date, true)
    if user then self.user_id=user.id end
end

def remove_suffix
  if self.callsign['/'] then self.callsign=Log.remove_suffix(self.callsign) end
end
 
def self.import_sota
  summits=Asset.where(asset_type: "summit")
  summits.each do |summit|
    self.update_sota_activation(summit)
  end
end

def self.import_pota
  summits=Asset.where(asset_type: "pota park").order(:code)
  summits.each do |summit|
    self.update_pota_activation(summit)
  end
end

def self.update_sota_activation(summit)
    #log in

    jscreds=Keycloak::Client.get_token(SOTA_USER, SOTA_PASSWORD, "sotadata", SOTA_SECRET)
    creds=JSON.parse(jscreds)
    access_token=creds["access_token"]
    id_token=creds["id_token"]

    activation_ids=[]
    puts "Summit: "+summit.code
    #url = "https://api-db.sota.org.uk/admin/find_summit?search="+summit.code
    #data = JSON.parse(open(url, {ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE}).read)
    #if data and data[0] then
    #  summitId=data[0]["SummitId"]
#      url = "https://api-db.sota.org.uk/admin/summit_history?summitID="+summitId.to_s
      #data = JSON.parse(open(url, {ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE}).read)
      url = URI.parse("https://api2.sota.org.uk/api/activations/"+summit.code)
      http=Net::HTTP.new(url.host, url.port)
      http.use_ssl=true
      http.verify_mode=OpenSSL::SSL::VERIFY_NONE

      req = Net::HTTP::Get.new("#{url.path}", 'Content-Type' => 'application/json', 'Authorization' => "Bearer "+access_token,  'connection' => 'keep-alive')
      res = http.request(req)
      data=JSON.parse(res.body)

#      if data and data["activations"] then
        if data and data.count>0 then 
        #puts "Activations: "+data["activations"].count.to_s
        puts "Activations: "+data.count.to_s
        newcount=0
        #data["activations"].each do |activation|
        data.each do |activation|
          sa=SotaActivation.new
          sa.asset_type='summit'
          sa.sota_activation_id=activation["id"].to_i
          #sa.callsign=activation["ownCallsign"].strip
          sa.callsign=Log.remove_suffix(activation["ownCallsign"].strip)
          puts "Activator: "+sa.callsign
          sa.summit_code=summit.code.strip
          #sa.summit_sota_id=summitId
          #if activation["ActivationDate"] then sa.date=activation["ActivationDate"].to_date  end
          if activation["activationDate"] then sa.date=activation["activationDate"].to_date.strftime("%Y-%m-%d")  end
          sa.qso_count=activation["qsos"]
          #sa.qso_count=activation["QSOs"]
          activation_ids+=[activation["id"]]
          dups=SotaActivation.where(sota_activation_id: sa.sota_activation_id).count
          if dups==0 then
            puts sa.callsign+": New!"
            newcount+=1
            sa.save
            user=User.find_by(callsign: sa.callsign)
            if not user then
              user=User.create(callsign: sa.callsign, activated: false, password: 'dummy', password_confirmation: 'dummy', timezone: 1)
            end
            if user then
              if Rails.env.production? then
                user.outstanding=true;user.save;Resque.enqueue(Scorer)
              else
                user.update_score
                user.check_awards
                user.check_district_awards
                user.check_region_awards
              end
            end 
          end
        end
        puts "New: "+newcount.to_s
      #end
    end
    

    #get chasers
    activation_ids.each do |aid|
      url = URI.parse("https://api-db2.sota.org.uk/logs/whochasedme/"+aid.to_s)
      http=Net::HTTP.new(url.host, url.port)
      http.use_ssl=true
      http.verify_mode=OpenSSL::SSL::VERIFY_NONE

      req = Net::HTTP::Get.new("#{url.path}", 'Content-Type' => 'application/json', 'Authorization' => "Bearer "+access_token,  'connection' => 'keep-alive')
      res = http.request(req)
      data=JSON.parse(res.body)
      if data and data["chases"] then
        if data["summary"] and data["summary"].count>0 then
          actdate=data["summary"].first["ActivationDate"]
          puts "chases: "+data["chases"].count.to_s
          newcount=0
          data["chases"].each do |chase|
            if chase["SummitCode"].strip==summit.code then #check not chaseof another summit same day
              sc=SotaChase.new
              sc.asset_type='summit'
              sc.sota_activation_id=aid
              sc.callsign=Log.remove_suffix(chase["OwnCallsign"].strip)
              sc.band=chase["Band"]
              sc.mode=chase["Mode"]
              acttime=chase["TimeOfDay"].strip
              sc.summit_code=summit.code.strip
              #sc.summit_sota_id=summitId
              sc.date=actdate
              sc.time=Time.parse(actdate+" "+acttime+" UTC")
              dups=SotaChase.where(sc.attributes.except("summit_sota_id","id", "updated_at", "created_at","user_id")).count
              if dups==0 then
                puts sc.callsign+": New!"
                newcount+=1
                sc.save
                user=User.find_by(callsign: sc.callsign)
                if not user then
                  user=User.create(callsign: sc.callsign, activated: false, password: 'dummy', password_confirmation: 'dummy', timezone: 1)
                end
                if user then
                  if Rails.env.production? then
                    user.outstanding=true;user.save;Resque.enqueue(Scorer)
                  else
                    user.update_score
                    user.check_awards
                    user.check_district_awards
                    user.check_region_awards
                  end
                end
              end
            end
          end       
        end
      end
      puts "New: "+newcount.to_s
    end 
  end

def self.update_pota_activation(asset)
    puts "Park: "+asset.code
    url = "https://api.pota.app/park/activations/"+asset.code.capitalize+"?count=all"
    data = JSON.parse(open(url, {ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE}).read)
    if data and data.count>0 then
      puts "Activations: "+data.count.to_s
      newcount=0
      data.each do |activation|
        sa=SotaActivation.new
        sa.asset_type='pota park'
        sa.callsign=Log.remove_suffix(activation["activeCallsign"].strip)
        sa.summit_code=asset.code.strip
        sa.summit_sota_id=nil
        if activation["qso_date"] then sa.date=activation["qso_date"].to_date  end
        sa.qso_count=activation["totalQSOs"]
        dups=SotaActivation.where(sa.attributes.except("id", "updated_at", "created_at","user_id")).count
        if dups==0 then
          newcount+=1
          sa.save
          user=User.find_by_callsign_date(sa.callsign, sa.date, true)

          if user then
              if Rails.env.production? then
                user.outstanding=true;user.save;Resque.enqueue(Scorer)
              else
                user.update_score
                user.check_awards
                user.check_district_awards
                user.check_region_awards
              end

          end
        end
      end
      puts "New: "+newcount.to_s
    end
  end
end

