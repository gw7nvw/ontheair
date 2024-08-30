require "test_helper"

class UserChasedTest < ActiveSupport::TestCase

  test "actiuvating log triggers chase for chasing party (only)" do
    user1=create_test_user
    user2=create_test_user
    asset1=create_test_asset
    log=create_test_log(user1,asset_codes: [asset1.code])
    contact=create_test_contact(user1,user2,log_id: log.id, asset1_codes: [asset1.code])
    
    assert user1.chased==[], "Activating user has not chased location 1"
    assert user2.chased==[asset1.code], "Chasing user has chased location 1"
  end

  test "chaser log triggers chase for chasing party only" do
    user1=create_test_user
    user2=create_test_user
    asset1=create_test_asset
    log=create_test_log(user1,asset_codes: [])
    contact=create_test_contact(user1,user2,log_id: log.id, asset2_codes: [asset1.code])
    
    assert user1.chased==[asset1.code], "Chasing user has chased location 1"
    assert user2.chased==[], "Activating user has not chased location 1"
  end

  test "single chase listed if both patries log the contact" do
    user1=create_test_user
    user2=create_test_user
    asset1=create_test_asset
    log1=create_test_log(user1, asset_codes: [asset1.code])
    contact1=create_test_contact(user1,user2,log_id: log1.id, asset1_codes: [asset1.code])
    log2=create_test_log(user2)
    contact2=create_test_contact(user2,user1,log_id: log2.id, asset2_codes: [asset1.code])
    
    assert user1.chased==[], "Activating user has not chased location 1"
    assert user2.chased==[asset1.code], "Chasing user has chased location 1 only once"
  end

  test "Can request specific asset types" do
    user1=create_test_user
    user2=create_test_user
    asset1=create_test_asset(asset_type: 'hut')
    log=create_test_log(user1, asset_codes: [asset1.code])
    contact=create_test_contact(user1,user2,log_id: log.id, asset1_codes: [asset1.code])

    assert user2.chased(asset_type: 'hut')==[asset1.code], "Chasing user has chased this hut: "+user2.chased(asset_type: 'hut').to_json
    assert user2.chased(asset_type: 'park')==[], "Chasing user has chased no parks"
    assert user1.chased(asset_type: 'hut')==[], "Activating user has not chased this hut"
  end

  test "Can request multiple asset types" do
    user1=create_test_user
    user2=create_test_user
    asset1=create_test_asset(asset_type: 'hut')
    asset2=create_test_asset(asset_type: 'park')
    log=create_test_log(user1, asset_codes: [asset1.code])
    contact=create_test_contact(user1,user2,log_id: log.id, asset1_codes: [asset1.code])
    log2=create_test_log(user1, asset_codes: [asset2.code])
    contact2=create_test_contact(user1,user2,log_id: log2.id, asset1_codes: [asset2.code])

    assert user2.chased(asset_type: 'hut, park').sort==[asset1.code, asset2.code].sort, "Chasing user has chased hut and park: "+user2.chased(asset_type: 'hut, park').to_json
    assert user2.chased(asset_type: 'island, lighthouse').sort==[], "Chasing user has not chased island or lighthouse: "+user2.chased(asset_type: 'island, lighthouse').to_json
  end

  test "minor assets not included unless requested" do 
    user1=create_test_user
    user2=create_test_user
    asset1=create_test_asset(asset_type: 'hut', minor: true)
    log=create_test_log(user1,asset_codes: [asset1.code])
    contact=create_test_contact(user1,user2,log_id: log.id, asset1_codes:[asset1.code])
    
    assert user1.chased==[], "Activating user does not list minor asset"
    assert user2.chased==[], "Chasing user does not list minor asset"

    assert assert user1.chased(include_minor: true)==[], 
         "Activating user does not lost this asset even with minor requested"
    assert assert user2.chased(include_minor: true)==[asset1.code], 
         "Chasing user has activated location 1 when minor is requested"
  end


  test "QRO contacts not included if QRP requested" do 
    user1=create_test_user
    user2=create_test_user
    asset1=create_test_asset(asset_type: 'hut')
    log=create_test_log(user1,asset_codes: [asset1.code])
    contact=create_test_contact(user1,user2,log_id: log.id, asset1_codes:[asset1.code])
    
    assert user2.chased(qrp: true)==[], "Chasing user does not list non-QRP contact (all)"
    assert user2.chased(qrp: true, asset_type: 'hut')==[], "Chasing user does not list non-QRP contact (hut)"

    assert user2.chased(qrp: false)==[asset1.code], "Can pass qrp=false as parameter"

    contact.is_qrp1=true
    contact.is_qrp2=true
    contact.save
    user1.reload

    assert user2.chased(qrp: true)==[asset1.code], "Chasing user lists QRP (party1) contact (all)"
    assert user2.chased(qrp: true, asset_type: 'hut')==[asset1.code], "Chasing user lists QRP (party1) contact (hut)"

    contact.is_qrp1=true
    contact.is_qrp2=false
    contact.save

    assert user2.chased(qrp: true)==[], "Chasing user does not list QRP (party2) contact (all)"
    assert user2.chased(qrp: true, asset_type: 'hut')==[], "Chasing user does not list QRP (party2) contact (hut)"

    contact.is_qrp1=false
    contact.is_qrp2=true
    contact.save

    assert user2.chased(qrp: true)==[asset1.code], "Chased user does list QRP (party2) contact (all)"
    assert user2.chased(qrp: true, asset_type: 'hut')==[asset1.code], "Chased user does list QRP (party2) contact (hut)"
  end

  test "Muliple references in an activation are all picked up in activations" do
    user1=create_test_user
    user2=create_test_user
    asset1=create_test_asset
    asset2=create_test_asset
    log=create_test_log(user1,asset_codes: [asset1.code, asset2.code])
    contact=create_test_contact(user1,user2,log_id: log.id, asset1_codes:[asset1.code, asset2.code])
    
    assert user2.chased==[asset1.code,asset2.code], "Chasing user has chased both locations"
    assert user1.chased==[], "Activating user not activated both locations"
  end

  test "Multiple chases of same reference generate only one all-time chase entry" do
    user1=create_test_user
    user2=create_test_user
    asset1=create_test_asset
    log1=create_test_log(user1,asset_codes: [asset1.code], date: 400.days.ago)
    contact1=create_test_contact(user1,user2,log_id: log1.id, asset1_codes: [asset1.code], time: 400.days.ago)
    log2=create_test_log(user1,asset_codes: [asset1.code], date: Time.now())
    contact2=create_test_contact(user1,user2,log_id: log2.id, asset1_codes: [asset1.code], time: Time.now())
    
    assert user2.chased==[asset1.code], "Chasing user sees multiply-chased location only once"
  end

  test "Multiple chases by_year in different UTC year listed twice" do
    user1=create_test_user
    user2=create_test_user
    asset1=create_test_asset
    log1=create_test_log(user1,asset_codes: [asset1.code], date: "2020-01-01".to_time)
    contact1=create_test_contact(user1,user2,log_id: log1.id, asset1_codes: [asset1.code], time: "2020-01-01 00:00:00".to_time)
    log2=create_test_log(user1,asset_codes: [asset1.code], date: "2019-12-31".to_time)
    contact2=create_test_contact(user1,user2,log_id: log2.id, asset1_codes: [asset1.code], time: "2019-12-31 23:59:59".to_time)
   
    assert user2.chased(by_year: true)==[asset1.code+" 2019", asset1.code+" 2020"], "Chasing user sees multiply-chased location twice for different years"
  end
  
  test "Multiple chases by_year in same UTC year listed once" do
    user1=create_test_user
    user2=create_test_user
    asset1=create_test_asset
    log1=create_test_log(user1,asset_codes: [asset1.code], date: "2020-01-01".to_time)
    contact1=create_test_contact(user1,user2,log_id: log1.id, asset1_codes: [asset1.code], time: "2020-01-01 00:00:00".to_time)
    log2=create_test_log(user1,asset_codes: [asset1.code], date: "2020-12-31".to_time)
    contact2=create_test_contact(user1,user2,log_id: log2.id, asset1_codes: [asset1.code], time: "2020-12-31 23:59:59".to_time)
   
    assert user2.chased(by_year: true)==[asset1.code+" 2020"], "Chasing user sees multiply-chased location once for same year"
  end
  
  test "Multiple chases by_day in different UTC day listed twice" do
    user1=create_test_user
    user2=create_test_user
    asset1=create_test_asset
    log1=create_test_log(user1,asset_codes: [asset1.code], date: "2020-01-02".to_time)
    contact1=create_test_contact(user1,user2,log_id: log1.id, asset1_codes: [asset1.code], time: "2020-01-02 00:00:00".to_time)
    log2=create_test_log(user1,asset_codes: [asset1.code], date: "2020-01-01".to_time)
    contact2=create_test_contact(user1,user2,log_id: log2.id, asset1_codes: [asset1.code], time: "2020-01-01 23:59:59".to_time)
    assert user2.chased(by_day: true)==[asset1.code+" 2020-01-01", asset1.code+" 2020-01-02"], "Chasing user sees multiply-chased location twice for different days"
  end
  
  test "Multiple chases by_day in same UTC day listed once" do
    user1=create_test_user
    user2=create_test_user
    asset1=create_test_asset
    log1=create_test_log(user1,asset_codes: [asset1.code], date: "2020-01-01".to_time)
    contact1=create_test_contact(user1,user2,log_id: log1.id, asset1_codes: [asset1.code], time: "2020-01-01 00:00:00".to_time)
    log2=create_test_log(user1,asset_codes: [asset1.code], date: "2020-01-01".to_time)
    contact2=create_test_contact(user1,user2,log_id: log2.id, asset1_codes: [asset1.code], time: "2020-01-01 23:59:59".to_time)
   
    assert user2.chased(by_day: true)==[asset1.code+" 2020-01-01"], "Chasing user sees multiply-chased location once for same day"
  end
  

  test "Multiple copies of reference in an chase generate only one entry" do
    user1=create_test_user
    user2=create_test_user
    asset1=create_test_asset
    asset2=create_test_asset
    log=create_test_log(user1,asset_codes: [asset1.code, asset2.code, asset1.code])
    contact=create_test_contact(user1,user2,log_id: log.id, asset1_codes: [asset1.code, asset2.code, asset1.code])
    
    assert user2.chased==[asset1.code,asset2.code], "Chasing user has chased both locations but repeated locn shown only once"
  end

  test "Chase using secondary callsign picked up in chased" do
    user1=create_test_user
    user2=create_test_user
    uc=create_callsign(user2) #secondary callsign
    asset1=create_test_asset
    log=create_test_log(user1,asset_codes: [asset1.code], date:Time.now)
    contact=create_test_contact(user1,user2,log_id: log.id, asset1_codes:[asset1.code], callsign2: uc.callsign)

    assert contact.callsign2==uc.callsign, "Secondary call applied to contact"
    assert user2.chased==[asset1.code], "Chasing user has chased location 1"
  end

  test "Chase using secondary callsign outside time not picked up in chased" do
    user1=create_test_user
    user2=create_test_user
    user3=create_test_user
    #expire user1 callsign 11 days ago
    uc1=UserCallsign.find_by(callsign: user2.callsign)
    uc1.to_date=11.days.ago
    uc1.save 
 
    #add user1's callsign to user3
    uc=create_callsign(user3, callsign: user2.callsign, from_date: 10.days.ago, to_date: 1.days.ago) #secondary callsign
    assert uc.callsign==user2.callsign, "User1 callsign applied to user3 as secondary call"

    asset1=create_test_asset
    log=create_test_log(user3,asset_codes: [asset1.code], date: 2.days.ago)
    contact=create_test_contact(user3,user2,log_id: log.id, asset1_codes: [asset1.code], callsign2: uc.callsign, time: 2.days.ago)

    assert contact.callsign2==uc.callsign, "Secondary call applied to contact"
    assert user3.chased==[asset1.code], "Chasing call with correct dates has chased location 1"
    assert user2.chased==[], "Another user with same call different dates to chaser has not chased location 1"
  end

end

