class ContactAssetLink < ActiveRecord::Base

def asset
  asset=Asset.find_by(code: self.asset_code)
end

def self.migrate_from_contacts
  cs=Contact.all
  cs.each do |c|
    if c.hut1_id and c.hut1 then
      cal=ContactAssetLink.new
      cal.contact_id=c.id
      cal.asset_type="hut"
      cal.asset_code=c.hut1.code
      cal.party=1
      cal.callsign=c.callsign1
      cal.chase_callsign=c.callsign2
      cal.save
    end  
    if c.park1_id and c.park1 then
      cal=ContactAssetLink.new
      cal.contact_id=c.id
      cal.asset_type="park"
      cal.asset_code=c.park1.code
      cal.party=1
      cal.callsign=c.callsign1
      cal.chase_callsign=c.callsign2
      cal.save
    end  
    if c.island1_id and c.island1 then
      cal=ContactAssetLink.new
      cal.contact_id=c.id
      cal.asset_type="island"
      cal.asset_code=c.island1.code
      cal.party=1
      cal.callsign=c.callsign1
      cal.chase_callsign=c.callsign2
      cal.save
    end  
    if c.summit1_id and c.summit1 then
      cal=ContactAssetLink.new
      cal.contact_id=c.id
      cal.asset_type="summit"
      cal.asset_code=c.summit1.summit_code
      cal.party=1
      cal.callsign=c.callsign1
      cal.chase_callsign=c.callsign2
      cal.save
    end  
    if c.hut2_id and c.hut2 then
      cal=ContactAssetLink.new
      cal.contact_id=c.id
      cal.asset_type="hut"
      cal.asset_code=c.hut2.code
      cal.party=2
      cal.callsign=c.callsign2
      cal.chase_callsign=c.callsign2
      cal.save
    end  
    if c.park2_id and c.park2 then
      cal=ContactAssetLink.new
      cal.contact_id=c.id
      cal.asset_type="park"
      cal.asset_code=c.park2.code
      cal.party=2
      cal.callsign=c.callsign2
      cal.chase_callsign=c.callsign2
      cal.save
    end  
    if c.island2_id and c.island2 then
      cal=ContactAssetLink.new
      cal.contact_id=c.id
      cal.asset_type="island"
      cal.asset_code=c.island2.code
      cal.party=2
      cal.callsign=c.callsign2
      cal.chase_callsign=c.callsign2
      cal.save
    end  
    if c.summit2_id and c.summit2 then
      cal=ContactAssetLink.new
      cal.contact_id=c.id
      cal.asset_type="summit"
      cal.asset_code=c.summit2.summit_code
      cal.party=2
      cal.callsign=c.callsign2
      cal.chase_callsign=c.callsign2
      cal.save
    end  
  end
end

end
