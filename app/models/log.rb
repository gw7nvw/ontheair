class Log < ActiveRecord::Base
  belongs_to :createdBy, class_name: "User"
  after_save { update_contacts }
  #attr_accessor :asset_names

  def asset_names
    asset_names=self.assets.map{|asset| asset.name}
    if !asset_names then asset_names="" end
    asset_names
  end

  def asset_code_names
    asset_names=self.assets.map{|asset| "["+asset.code+"] "+asset.name}
    if !asset_names then asset_names="" end
    asset_names

  end

  def assets
    if self.asset_codes then Asset.where(code: self.asset_codes) else [] end
  end  

  def contacts
    if self.id and self.id>0 then
      cs=Contact.where(log_id: self.id)
    else 
      nil
    end
    cs
  end

  def update_contacts
    contacts=Contact.where(:log_id => self.id)
    contacts.each do |cle|
      cle.callsign1=self.callsign1
      cle.date=self.date
      cle.loc_desc1=self.loc_desc1
      cle.is_qrp1=self.is_qrp1
      cle.power1=self.power1
      cle.is_portable1=self.is_portable1
      cle.x1=self.x1
      cle.y1=self.y1
      cle.location1=self.location1
      cle.convert_to_utc(User.find_by(callsign: cle.callsign1))
      cle.asset1_codes=self.asset_codes
      cle.save
    end
  end

def self.migrate_to_codes
   logs=Log.all
    logs.each do |log|
      codes=[]
      if log.hut1_id then codes.push(Hut.find_by(id: log.hut1_id).code) end 
      if log.park1_id then codes.push(Park.find_by(id: log.park1_id).code) end
      if log.island1_id then codes.push(Island.find_by(id: log.island1_id).code) end
      if log.summit1_id and log.summit1_id.length>0 then codes.push(SotaPeak.find_by(short_code: log.summit1_id).summit_code) end
      log.asset_codes=codes
      log.save
    end
end


end
